//
//  WOHTMLParser.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//

import Foundation

/**
 * This parser parses "old-style" .wo templates. It does *not* process
 * the whole HTML of the file, it only searches for text sections which start
 * with `<wo:`. That way you can process "illegal" HTML code, eg:
 *
 *     <a href="<wo:MyLink/>">Hello World</a>
 *
 * The syntax is:
 *
 *     <wo:wod-name>...</wo:wod-name>
 *
 * ### Internals
 *
 * The root parse function is _parseElement() which calls either
 * _parseWOElement() or _parseHashElement() if it finds a NGObjWeb tag at the
 * beginning of the buffer.
 * If it doesn't it collects all content until it encounteres an NGObjWeb tag,
 * and reports that content as "static text" to the callback.
 *
 * Parsing a dynamic element is:
 *
 * - parse the start tag
 * - parse the attributes
 * - parse the contents, static strings and elements,
 *   add content to a children array
 * - produce WOElement by calling
 *   `-dynamicElementWithName:attributes:contentElements:`
 * - parse close tag
 *
 * Note: This is a straight port of the Java port of the ObjC parser and
 *       therefore somewhat clumsy.
 *
 * This class does not really construct the dynamic elements, this is done by
 * the `WOWrapperTemplateBuilder`. The builder acts as the `WOHTMLParserHandler`
 * for this class.
 */
open class WOHTMLParser : WOTemplateParser {
  // TODO: Error handling. Sometimes we want to throw, sometimes we don't.
  //       This port mostly just logs.
  
  let log = WOPrintLogger.shared
  
  open var handler : WOTemplateParserHandler?

  /* do process markers inside HTML tags ? */
  let skipPlainTags          = false
  let compressHTMLWhitespace = true
  let omitComments           = true
  let elementNameAliasMap    = WOShortNameAliases
  
  var buffer = UnsafeBufferPointer<UInt8>(start: nil, count: 0)
  var idx    = 0
  var url    : URL? = nil

  open func parseHTMLData(_ url: URL) throws -> [ WOElement ] {
    let data = try Data(contentsOf: url)
    return try parse(data, at: url)
  }
  
  open func parse(_ data: Data, at url: URL? = nil) throws -> [ WOElement ] {
    let len = data.count
    guard len > 0 else { return [] }
    
    #if swift(>=5)
      return try data.withUnsafeBytes() {
        ( ptr : UnsafeRawBufferPointer ) -> [ WOElement ] in
        return try parse(ptr.bindMemory(to: UInt8.self), at: url)
      }
    #else
      return try data.withUnsafeBytes() {
        ( ptr : UnsafePointer<UInt8> ) -> [ WOElement ] in
        return try parse(UnsafeBufferPointer(start: ptr, count: len), at: url)
      }
    #endif
  }
  
  open func parse(_ data: UnsafeBufferPointer<UInt8>, at url: URL? = nil) throws
            -> [ WOElement ]
  {
    buffer   = data
    idx      = 0
    self.url = url
    defer {
      buffer   = UnsafeBufferPointer<UInt8>(start: nil, count: 0)
      idx      = 0
      self.url = nil
    }
    
    return try parse()
  }
  
  open func parse() throws -> [ WOElement ] {
    guard handler?.parser(self, willParseHTMLData: buffer) ?? true else {
      return []
    }
    
    var topLevel = [ WOElement ]()
    
    while idx < buffer.count {
      do {
        if let element = try parseElement() {
          topLevel.append(element)
        }
        else {
          break
        }
      }
      catch {
        handler?.parser(self, failedParsingHTMLData: buffer, with: topLevel,
                        error: error)
        throw error
      }
    }
    
    handler?.parser(self, finishedParsingHTMLData: buffer, with: topLevel)
    return topLevel
  }
  
  
  // MARK: - Parsing
  
  var position : ( line : Int, column : Int ) {
    var line   = 1
    var lastNL = 0
    for i in 0..<idx {
      if buffer[i] == 10 { line += 1; lastNL = i }
    }
    return ( line, idx - lastNL )
  }
  
  func parseElement() throws -> WOElement? {
    guard idx < buffer.count else { return nil }
    
    // TBD: we do not raise but rather expose parse errors to the page. FIXME.
    
    if isHashTag      { return try parseInlineElement() }
    if isWOTag        { return try parseWOElement() }
    
    if isHashCloseTag {
      let start = idx
      _ = consumeHashCloseTag()
      assert(idx > start, "did not consume close tag??")
      let s = getString(at: start, length: idx - start)
      log.error("unexpected hash close tag (</#...>):", s, position)
      return WOStaticHTMLElement(s.htmlEscaped)
    }
    
    if isWOCloseTag {
      let start = idx
      _ = consumeWOCloseTag()
      assert(idx > start, "did not consume close tag??")
      let s = getString(at: start, length: idx - start)
      log.error("unexpected WEBOBJECT close tag:", s, position)
      return WOStaticHTMLElement(s.htmlEscaped)
    }
    
    return try parseRawContent()
  }
  
  func parseRawContent() throws -> WOElement? {
    guard idx < buffer.count else { return nil }
    
    var containsComment = false
    var containsMultiWS = !compressHTMLWhitespace
    
    /* parse text/tag content */
    let startPos = idx
    let len      = buffer.count
    while idx < len {
      
      /* scan until we find a tag marker '<' */
      var lastWasWS = false
      while idx < len && buffer[idx] != C.lt {
        if !containsMultiWS {
          let thisIsWS = isHTMLSpace(buffer[idx])
          if thisIsWS && lastWasWS { containsMultiWS = true }
          lastWasWS = thisIsWS
        }
        idx += 1
      }
      guard idx < buffer.count else { break } // EOF

      /* check whether its a tag which we parse */
      if !shouldContinueParsingText { break }
      
      if isComment {
        containsComment = true
        idx += 4 /// skip <!--
        
        while idx < len { // scan for -->
          if buffer[idx] == C.dash, (idx + 2) < len,
             buffer[idx + 1] == C.dash && buffer[idx + 2] == C.gt
          { // found
            idx += 3
            break
          }
          idx += 1
        }
        guard idx < buffer.count else { break } // EOF
      }
      else {
        // skip '<', read usual tag
        idx += 1
        guard idx < buffer.count else { break } // EOF
        
        if skipPlainTags {
          /* Skip until end of HTML tag (not wo:/#-tag). If this is enabled,
           * WO-tags inside regular HTML tags are NOT processed (aka invalid
           * tag nesting is denied, eg this would NOT work:
           *   <a href="<wo:MyLink/>">...
           */
          while idx < len && buffer[idx] != C.gt {
            let c = buffer[idx]
            if c == C.quote || c == C.dquote {
              idx += 1
              while idx < len && buffer[idx] != c { idx += 1 }
              if idx < len { idx += 1 } // skip closing
            }
            else {
              idx += 1
            }
          }
          
          guard idx < buffer.count else { break } // EOF
        }
        else {
          idx += 1
        }
      }
    }
    
    let ilen = idx - startPos
    guard ilen > 0 else { return nil } // no content
    
    var s = getString(at: startPos, length: ilen)
    #if false // this is actually valid ;-)
      assert(!s.contains("</WEBOBJECT"))
    #endif
    
    if omitComments && containsComment {
      s = stringByRemovingHTMLComments(s)
    }
    if compressHTMLWhitespace && containsMultiWS {
      s = stringByCompressingWhiteSpace(s, CharacterSet.whitespacesAndNewlines)
    }

    return WOStaticHTMLElement(s)
  }
  
  func parseInlineElement() throws -> WOElement? {
    guard idx < buffer.count else { return nil }
    guard isHashTag          else { return nil }
    
    var wasWO = false
    idx += 1 // skip <
    if buffer[idx] == C.hash {
      idx += 1 // skip #
    }
    else if buffer[idx] == C.lower_w {
      idx += 3 // skip wo:
      wasWO = true
    }
    let hadSlashAfterHash = buffer[idx] == C.slash
    
    if hadSlashAfterHash {
      /* a tag starting like this: "<#/", probably a typo */
      log.error("typo in hash close tag ('<#/' => '</#').")
    }

    /* parse tag name */
    guard var name = try parseStringValue() else { return nil }
    skipSpaces()

    /* WOnder hacks (not sure how exactly its done there ...) */
    if wasWO { name = replaceShortWOName(name) }

    var attrs = try parseTagAttributes()
    guard idx < buffer.count else {
      log.error("unexpected EOF: missing '>' in hash tag (EOF).")
      return nil
    }

    /* parse tag end (> or /) */
    guard buffer[idx] == C.gt || buffer[idx] == C.slash else {
      log.error("missing '>' in hash element tag.")
      return nil
    }
    
    var isAutoClose = false
    var foundEndTag = false
    var children    = [ WOElement ]()
    
    if buffer[idx] == C.gt {  /* hashtag is closed */
      /* has sub-elements (<wo:name>...</wo:name>) */
      idx += 1; // skip '>'
      while idx < buffer.count {
        if isHashCloseTag {
          foundEndTag = true
          break
        }
        
        if let subelement = try parseElement() {
          children.append(subelement)
        }
      }
    }
    else { /* is an empty tag (<wo:name/>) */
      /* has no sub-elements (<wo:name/>) */
      idx += 1 // skip '/'
      isAutoClose = true
      guard idx < buffer.count && buffer[idx] == C.gt else {
        log.error("missing '>' in hash element tag (EOF).")
        return nil
      }
      idx += 1 // skip >
    }
    
    // produce elements
    
    attrs["NAME"] = name
    
    guard let element = handler?.parser(self, dynamicElementFor: name,
                                        attributes: attrs,
                                        children: children) else {
      log.error("could not build hash element:", name)
      return nil
    }
    
    guard foundEndTag || isAutoClose else {
      log.error("did not find close tag (</wo:\(name)>)", position)
      return nil
    }
    
    if !isAutoClose {
      _ = consumeHashCloseTag(name)
    }

    return element
  }
  
  func consumeHashCloseTag(_ name: String? = nil) -> Bool {
    /* skip close tag ('</wo:name>') */
    guard isHashCloseTag else {
      assert(isHashCloseTag, "invalid parser state \(name ?? "-")")
      log.error("invalid parser state:", name ?? "-")
      return false
    }
    
    if buffer[idx + 2] == C.hash {
      idx += 3 // skip `</#`
    }
    else if buffer[idx + 2] == C.lower_w {
      idx += 5 // skip `</wo:`
    }
    
    while idx < buffer.count && buffer[idx] != C.gt { idx += 1 }
    if idx < buffer.count {
      idx += 1 // skip `>`
    }
    return true
  }
  
  func parseWOElement() throws -> WOElement? {
    guard idx < buffer.count else { return nil }
    guard isWOTag            else { return nil }
    
    idx += 10 // skip `<WEBOBJECT`
    
    let attrs = try parseTagAttributes()
    
    guard let name = attrs["NAME"] ?? attrs["name"], !name.isEmpty else {
      log.error("missing name in WEBOBJECT element tag.", attrs)
      return nil
    }
    guard skipSpaces(), buffer[idx] == C.gt else {
      log.error("unexpected EOF: missing '>' in WEBOBJECT tag (EOF).")
      return nil
    }
    idx += 1
    
    var foundEndTag = false
    var children    = [ WOElement ]()
    
    while idx < buffer.count {
      if isWOCloseTag {
        foundEndTag = true
        break
      }
      
      if let subelement = try parseElement() {
        children.append(subelement)
      }
    }
    
    guard let element = handler?.parser(self, dynamicElementFor: name,
                                        attributes: attrs,
                                        children: children) else {
      log.error("could not build WEBOBJECT element:", name)
      return nil
    }

    guard foundEndTag else {
      log.error("did not find close tag (</WEBOBJECT>)", position)
      return nil
    }
    
    _ = consumeWOCloseTag(name)
    
    return element
  }
  
  func consumeWOCloseTag(_ name: String? = nil) -> Bool {
    /* skip close tag ('</WEBOBJECT>') */
    guard isWOCloseTag else {
      assert(isWOCloseTag, "invalid parser state \(name ?? "-")")
      log.error("invalid parser state:", name ?? "-")
      return false
    }
    idx += 11; // skip '</WEBOBJECT'
    
    while idx < buffer.count && buffer[idx] != C.gt { idx += 1 }
    if idx < buffer.count {
      idx += 1 // skip `>`
    }
    return true
  }
  
  /**
   * This method parses a set of tag key=value attributes, eg:
   *
   *     style = "green" size = 4 disabled
   *
   * Values are not required to be quoted.
   *
   * @return the parsed tag attributes as a String,String Map
   */
  func parseTagAttributes() throws -> [ String : String ] {
    var attrs = [ String : String ]()
    
    while idx < buffer.count {
      guard skipSpaces() else { break }
      
      guard let key = try parseStringValue() else {
        break // ended
      }
      
      /* The following parses:  space* '=' space* */
      guard skipSpaces() else {
        log.error("expected '=' after key in attributes", key)
        break
      }
      
      if buffer[idx] == C.equal {
        idx += 1 // skip `=`
        
        guard skipSpaces(), let value = try parseStringValue() else {
          log.error("expected value after key '=' in attributes", key)
          break
        }
        attrs[key] = value
      }
      else {
        attrs[key] = key // disabled=disabled
      }
    }
    
    return attrs
  }
  
  /**
   * This parses quoted and unquoted strings. Unquoted strings are terminated
   * by `>`, `=`, `/` and HTML space.
   *
   * @return a String, or null on EOF/empty-string
   */
  func parseStringValue() throws -> String? {
    guard skipSpaces() else { return nil }
    
    let len = buffer.count
    var pos = idx
    let c   = buffer[pos]
    
    func isBreakChar(_ c: UInt8) -> Bool {
      return c == C.gt || c == C.slash || c == C.equal
    }
    guard !isBreakChar(c) else { return nil }
    
    if c == C.quote || c == C.dquote {
      let quot = c
      pos += 1
      
      let startPos = pos
      
      while pos < len && buffer[pos] != quot { pos += 1 }
      if pos >= len {
        idx = pos
        throw ParseError.quotedStringNotClosed
      }
      
      let ilen = pos - startPos
      idx = pos + 1
      return getString(at: startPos, length: ilen)
    }
    
    // without quotes
    let startPos = pos
    while pos < len && !isBreakChar(buffer[pos]) && !isHTMLSpace(buffer[pos]) {
      pos += 1
    }
    idx = pos
    let ilen = pos - startPos
    if ilen < 1 { return nil } // wasn't a string
    
    return getString(at: startPos, length: ilen)
  }
  
  func getString(at index: Int, length: Int) -> String {
    guard length > 0 else { return "" }
    let base = buffer.baseAddress?.advanced(by: index)
    let data = UnsafeBufferPointer(start: base, count: length)
    return String(decoding: data, as: UTF8.self)
  }
  

  /**
   * This returns false if the current parse position contains a tag which we
   * understand and need to process.
   *
   * @return true if the parser should continue parsing raw text, or false
   */
  var shouldContinueParsingText : Bool {
    return !isHashTag && !isHashCloseTag && !isWOTag && !isWOCloseTag
  }
  
  /**
   * Checks for
   *
   *     <wo:.> (len 6)
   *     <#.>   (len 4)
   *
   * @return true if the parse position contains a wo: tag
   */
  var isHashTag : Bool {
    guard handler != nil         else { return false }
    guard idx + 4 < buffer.count else { return false }
    guard buffer[idx] == C.lt    else { return false }
    
    /* eg <wo:WOHyperlink> */
    if buffer[idx + 1] == C.lower_w &&
       buffer[idx + 2] == C.lower_o &&
       buffer[idx + 3] == C.colon   &&
       idx + 6 < buffer.count
    {
      return true
    }
    
    /* eg: <#Hello> */
    return buffer[idx + 1] == C.hash
  }
  
  /**
   * Checks for
   *
   *     </wo:.> (len 7)
   *     </#.>   (len 5)
   *
   * @return true if the parse position contains a wo: close tag
   */
  var isHashCloseTag : Bool {
    guard handler != nil         else { return false }
    guard idx + 5 < buffer.count else { return false }
    guard buffer[idx] == C.lt && buffer[idx + 1] == C.slash else {
      return false
    }
    
    /* eg </wo:WOHyperlink> */
    if buffer[idx + 2] == C.lower_w &&
       buffer[idx + 3] == C.lower_o &&
       buffer[idx + 4] == C.colon   &&
       idx + 7 < buffer.count
    {
      return true
    }
    
    /* eg: </#Hello> */
    return buffer[idx + 2] == C.hash
  }
  
  /**
   * check for `<WEBOBJECT .......>` (len 19) (lowercase is allowed)
   */
  var isWOTag : Bool {
    guard handler != nil          else { return false }
    guard idx + 18 < buffer.count else { return false }
    guard buffer[idx] == C.lt     else { return false }

    return matchCI("<WEBOBJECT")
  }
  
  /**
   * check for `</WEBOBJECT>` (len 12) (lowercase is allowed)
   */
  var isWOCloseTag : Bool {
    guard handler != nil          else { return false }
    guard idx + 12 <= buffer.count else { return false }
    guard buffer[idx] == C.lt && buffer[idx + 1] == C.slash else {
      return false
    }

    return matchCI("</WEBOBJECT")
  }
  
  var isComment : Bool {
    /* checks whether a comment is upcoming (<!--), doesn't consume */
    guard idx + 7 < buffer.count else { return false }
    guard buffer[idx] == C.lt    else { return false }
    
    return buffer[idx + 1] == C.exclamation &&
           buffer[idx + 2] == C.dash        &&
           buffer[idx + 3] == C.dash
  }

  func isHTMLSpace(_ c: UInt8) -> Bool {
    switch c {
      case C.space, C.tab, C.cr, C.nl: return true
      default: return false
    }
  }
  
  @discardableResult
  func skipSpaces() -> Bool {
    while idx < buffer.count && isHTMLSpace(buffer[idx]) {
      idx += 1
    }
    return idx < buffer.count
  }
  
  func matchCI(_ s: String) -> Bool {
    let utf8  = s.utf8
    let count = utf8.count
    guard idx + count <= buffer.count else { return false }
    
    var pos = idx
    for c in utf8 {
      let bc = buffer[pos]
      if bc == c { pos += 1; continue }
      
      let uc  = (C.lower_a...C.lower_z).contains(c)  ? c  - 32 : c
      let ubc = (C.lower_a...C.lower_z).contains(bc) ? bc - 32 : bc
      guard ubc == uc else { return false }
      pos += 1
    }
    
    return true
  }
  
  func stringByRemovingHTMLComments(_ s: String) -> String {
    // TODO: port me
    return s
  }
  func stringByCompressingWhiteSpace(_ s: String, _ ws: CharacterSet)
       -> String
  {
    // TODO: port me
    return s
  }
  
  func replaceShortWOName(_ name: String) -> String {
    return elementNameAliasMap[name] ?? name
  }


  // MARK: - Errors
  
  public enum ParseError : Swift.Error {
    case quotedStringNotClosed
  }
  
  public struct Error : Swift.Error, SmartDescription {
    public let error   : String
    public let line    : Int?
    public let context : String?
    public let url     : URL?
    
    public func appendToDescription(_ ms: inout String) {
      if let url  = url  { ms += " url=\(url)"   }
      if let line = line { ms += " line=\(line)" }
      ms += " error=\(error)"
      if let context = context { ms += " context|\(context)|" }
    }
  }
}

fileprivate enum C {
  
  static let space       : UInt8 = 32
  static let nl          : UInt8 = 10
  static let cr          : UInt8 = 13
  static let tab         : UInt8 = 9
  
  static let lt          : UInt8 = 60
  static let gt          : UInt8 = 62
  static let hash        : UInt8 = 35
  static let colon       : UInt8 = 58
  static let slash       : UInt8 = 47
  static let exclamation : UInt8 = 33
  static let dash        : UInt8 = 45
  static let dquote      : UInt8 = 34
  static let quote       : UInt8 = 39
  static let equal       : UInt8 = 61

  static let upper_A     : UInt8 = 65
  static let upper_Z     : UInt8 = 90
  static let lower_a     : UInt8 = 97
  static let lower_o     : UInt8 = 111
  static let lower_w     : UInt8 = 119
  static let lower_z     : UInt8 = 122
}
