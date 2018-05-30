//
//  PropertyListParser.swift
//  SwiftObjects
//
//  Created by Helge Hess on 17.05.18.
//

import struct Foundation.Data

/**
 * This class implements a parser for the old-style property list format. You
 * would not usually invoke it directly, but rather use the
 * {@link NSPropertyListSerialization} utility function class, eg:
 *
 *     let person = NSPropertyListSerialization.dictionaryForString
 *       ("{ lastname = Duck; firstname = Donald; }");
 *
 * ### Property Values
 *
 * The parser returns those objects as values:
 *
 * - String                   (quoted like "Hello World" or unquoted)
 * - Array<Any?>              (eg: "( Hello, World, 15 )")
 * - Dictionary<String, Any?> (eg: "{ lastname = Duck; age = 100; }")
 * - Int/Double               (eg: 100.00, -100.10)
 * - Bool                     (true,false,YES,NO)
 * - Data                     (eg: &lt;0fbd777 1c2735ae&gt;)
 *
 * #### Error Handling
 *
 * Call parse(). If it returns 'null', retrieve the
 * lastException() from the parser for details.
 *
 * #### Thread Safety
 *
 * This class is not threadsafe. Instantiate a new object per parsing
 * process.
 */
open class PropertyListParser {
  // A Swift port of the Java port of the ObjC parser.
  
  let useValueKeys   : Bool
  let allowNilValues : Bool
  
  var buffer         = UnsafeBufferPointer<UInt8>(start: nil, count: 0)
  var idx            = 0
  var errors         = [ Swift.Error ]()
  
  final let tokens = Syntax()
  
  public init(useValueKeys: Bool = false, allowNilValues: Bool = false) {
    self.useValueKeys   = useValueKeys
    self.allowNilValues = allowNilValues
  }
  
  open func parse(_ s: String) throws -> Any? {
    guard !s.isEmpty else { return nil }
    guard let data = s.data(using: .utf8) else { return nil }
    return try parse(data)
  }
  
  open func parse(_ data: Data) throws -> Any? {
    let len = data.count
    guard len > 0 else { return nil }
    
    return try data.withUnsafeBytes() {
      ( ptr : UnsafePointer<UInt8> ) -> Any? in
      try parse(UnsafeBufferPointer(start: ptr, count: len))
    }
  }
  
  open func parse(_ data: UnsafeBufferPointer<UInt8>) throws -> Any? {
    buffer  = data
    idx     = 0
    errors.removeAll()
    defer {
      buffer = UnsafeBufferPointer<UInt8>(start: nil, count: 0)
      idx    = 0
    }
    
    let value = parse()
    
    if value == nil {
      if errors.count > 0 { throw errors[0] } // TODO: combine
      return value
    }
    return value
  }
  
  open func parse() -> Any? {
    return parseProperty()
  }
  
  func reportError(_ error: PropertyListParseError) -> Bool {
    errors.append(error)
    return true
  }
  
  /**
   * Parse an arbitary property value. This is called by the top-level, its
   * called for array elements and for dictionary values.
   * Its called for dictionary keys if `useValueKeys` is true.
   *
   * The method first skips comments and then checks the first char of the
   * property:
   *
   * - `"` or `'` will trigger _parseQString()
   * - `{` will trigger _parseDict()
   * - `(` will trigger _parseArray()
   * - `<` will trigger _parseData()
   * - if it starts with a digit or '-', attempt to parse it as a number
   *     (but could be a String like 001.html). If the parsing succeeds
   *     (no NumberFormatException), a Number will be returned
   * - `YES`, `NO`, `true`, `false` - will be returned as Boolean objects
   * - `null`, `nil` - will be returned as Java null
   * - all other Strings will trigger _parseKeyPath()
   */
  func parseProperty() -> Any? {
    guard skipComments() else { return nil } // EOF

    switch buffer[idx] {
      case tokens.stringQuote, tokens.stringQuote2:
        return parseQuotedString()
      
      case tokens.openDict:
        if useValueKeys {
          let dict : Dictionary<AnyHashable, Any?>? = parseDictionary()
          if allowNilValues { return dict }
          return dict?.compactMapValues { $0 }
        }
        else {
          let dict : Dictionary<String, Any?>? = parseDictionary()
          if allowNilValues { return dict }
          return dict?.compactMapValues { $0 }
        }
      
      case tokens.openArray:
        let array : Array<Any?>? = parseArray()
        if allowNilValues { return array }
        #if swift(>=4.1)
          return array?.compactMap { $0 }
        #else
          return array.flatMap { $0 }
        #endif
      
      case tokens.openData:      return parseData()
      case C.n0...C.n9, C.minus: return parseDigit()
      
      default:
        if let b = parseBool() { return b   }
        else if parseNil()     { return nil }
        else                   { return parseKeyPath() }
    }
  }
  
  /**
   * Skip comments in the input buffer. We support `/ *` and `//` style
   * comments.
   */
  func skipComments() -> Bool {
    guard idx < buffer.count else { return false }
    
    var pos = idx
    let len = buffer.count
    while pos < len {
      let c0 = buffer[pos]
      guard !isWhitespace(c0)      else { pos += 1; continue }
      guard c0 == C.slash, len > 1 else { break }
      
      let c1 = buffer[pos + 1]
      guard c1 == C.slash || c1 == C.star else { break }
      
      if c1 == C.slash { // single line comment
        pos += 2
        while pos < len && buffer[pos] != C.nl { pos += 1 }
        if pos >= len { break }
      }
      else if c1 == C.star { // multiline comment
        var commentIsClosed = false
        pos += 2 // skip / *
        
        while (pos + 1) < len {
          if buffer[pos] == C.star && buffer[pos + 1] == C.slash {
            commentIsClosed = true
            pos += 2
            break
          }

          pos += 1
        }
        
        if !commentIsClosed {
          if !reportError(.commentNotClosed(pos)) { return false }
        }
      }
    }
    
    return move(to: pos)
  }
  
  func parseIdentifier() -> String? {
    guard skipComments() else {
      _ = reportError(.expectedIdentifier(idx))
      return nil
    }
    
    var pos  = idx
    let len  = buffer.count
    
    while pos < len && isIDChar(buffer[pos]) { pos += 1 }
    guard pos > idx else {
      _ = reportError(.expectedIdentifier(idx))
      return nil
    }
    
    let data = UnsafeBufferPointer(start: buffer.baseAddress?.advanced(by: idx),
                                   count: pos - idx)
    idx = pos
    return String(decoding: data, as: UTF8.self)
  }
  
  /**
   * This is called by _parseProperty if the property could not be identified
   * as a primitive value (eg a Number or quoted String). Example:
   *
   *     person.address.street
   *
   * But *NOT*:
   *
   *     "person.address.street"
   *
   * The method parses a set of identifiers (using _parseIdentifier()) which
   * is separated by a dot.
   *
   * Its also called by the WOD parsers _parseAssociationProperty() method.
   *
   * @return the parsed String, eg "person.address.street"
   */
  func parseKeyPath() -> String? {
    guard skipComments() else {
      _ = reportError(.expectedKeyPathIdentifier(idx))
      return nil
    }
    
    guard var keyPath = parseIdentifier() else {
      _ = reportError(.expectedKeyPathIdentifier(idx))
      return nil
    }
    
    while idx < buffer.count && buffer[idx] == C.dot {
      idx += 1 // skip .
      keyPath += "."
      
      guard let nextID = parseIdentifier() else {
        if !reportError(.expectedKeyPathIdentifier(idx)) { return nil }
        break
      }
      
      keyPath += nextID
    }
    
    return keyPath
  }
  
  func parseDigit() -> Any? {
    guard skipComments() else {
      _ = reportError(.expectedDigit(idx))
      return nil
    }
    
    let hasSign = buffer[idx] == C.minus || buffer[idx] == C.plus
    var pos     = hasSign ? idx + 1 : idx
    var hadDot  = false
    while pos < buffer.count {
      let c0 = buffer[pos]
      guard (C.n0...C.n9).contains(c0) || (!hadDot && c0 == C.dot) else {
        break
      }
      if !hadDot { hadDot = c0 == C.dot }
      pos += 1
    }
    
    let data = UnsafeBufferPointer(start: buffer.baseAddress?.advanced(by: idx),
                                   count: pos - idx)
    idx = pos
    let s = String(decoding: data, as: UTF8.self)
    if hadDot {
      // TODO: support DecimalNumber
      return Double(s)
    }
    else {
      return Int(s)
    }
  }
  
  func parseBool() -> Bool? {
    guard skipComments() else {
      _ = reportError(.expectedDigit(idx)) // TODO
      return nil
    }

    let c0 = buffer[idx]
    switch c0 {
      case C.upper_Y, C.upper_N, C.lower_t, C.lower_f:
        if consume("YES")   { return true  }
        if consume("NO")    { return false }
        if consume("true")  { return true }
        if consume("false") { return false }
        return nil
      default:
        return nil
    }
  }
  func parseNil() -> Bool {
    guard skipComments() else {
      _ = reportError(.expectedDigit(idx)) // TODO
      return false
    }
    guard buffer[idx] == C.lower_n else { return false }
    if consume("nil")  { return true  }
    if consume("null") { return false }
    return false
  }
  
  /**
   * Parses a quoted string, eg:
   *
   *     "Hello World"
   *     'Hello World'
   *     "Hello \"World\""
   *
   */
  func parseQuotedString() -> String? {
    guard skipComments() else {
      _ = reportError(.expectedQuotedString(idx))
      return nil
    }

    let quoteChar = buffer[idx]
    guard quoteChar == tokens.stringQuote ||
          quoteChar == tokens.stringQuote2 else
    {
      _ = reportError(.expectedQuotedString(idx))
      return nil
    }
    
    var pos      = idx + 1
    let len      = buffer.count
    let startPos = pos
    var containsEscaped = false
    
    while pos < len && buffer[pos] != quoteChar {
      if buffer[pos] == tokens.stringEscape {
        containsEscaped = true
        pos += 1
        guard pos < len else {
          if !reportError(.escapeInQuoteNotFinished(idx)) { return nil }
          break
        }
      }
      pos += 1
    }
  
    let ilen = pos - startPos
    if pos >= len {
      if !reportError(.quotedStringNotClosed(pos)) { return nil }
    }
    else {
      pos += 1 // skip quote
    }
    idx = pos
    
    if ilen == 0 { return "" } // empty string
    
    if !containsEscaped {
      let base = buffer.baseAddress?.advanced(by: startPos)
      let data = UnsafeBufferPointer(start: base, count: ilen)
      return String(decoding: data, as: UTF8.self)
    }
    
    // unescape

    var unescaped = ContiguousArray<UInt8>()
    unescaped.reserveCapacity(ilen)

    var upos = pos
    let uend = upos + ilen
    while upos < uend {
      if buffer[upos] == C.backslash && (upos + 1) < uend {
        upos += 1
        switch buffer[upos] {
          case C.lower_n: unescaped.append(C.nl)
          case C.lower_t: unescaped.append(C.tab)
          case C.lower_r: unescaped.append(C.cr)
          default: break
        }
      }
      unescaped.append(buffer[upos])
      upos += 1
    }
    return String(decoding: unescaped, as: UTF8.self)
  }
  
  func parseData() -> Data? {
    guard skipComments() else {
      _ = reportError(.expectedData(idx))
      return nil
    }
    guard buffer[idx] == tokens.openData else {
      _ = reportError(.expectedData(idx))
      return nil
    }
    idx += 1 // skip <
    
    var data = Data()
    
    var isLowNibble = false
    var value       : UInt8 = 0x0
    
    while idx < buffer.count && buffer[idx] != tokens.closeData {
      let c0 = buffer[idx]
      
      if c0 == C.space { idx += 1; continue }
      
      guard let nibbleValue = valueOfHexChar(c0) else {
        if reportError(.malformedData(idx)) { return nil }
        idx += 1
        continue
      }
      
      if !isLowNibble {
        value = (nibbleValue << 4) & 0xF0
      }
      else {
        value |= nibbleValue
        data.append(value)
      }
      isLowNibble = !isLowNibble
      idx += 1
    }
    
    if isLowNibble || idx >= buffer.count {
      if reportError(.malformedData(idx)) { return nil }
    }
    idx += 1 // skip >
    
    return data
  }
  
  func parseDictionaryKey() -> AnyHashable? {
    guard idx < buffer.count else { return nil }
    if useValueKeys {
      guard let value = parseProperty() else { return nil }
      guard let key = value as? AnyHashable else {
        _ = reportError(.invalidDictionaryKey(value))
        return nil
      }
      return key
    }
    if buffer[idx] == tokens.stringQuote || buffer[idx] == tokens.stringQuote2 {
      return parseQuotedString()
    }
    return parseIdentifier()
  }
  
  func parseDictionary<T: Hashable>() -> Dictionary<T, Any?>? {
    guard skipComments() else {
      _ = reportError(.expectedDictionary(idx))
      return nil
    }
    
    guard buffer[idx] == tokens.openDict else {
      _ = reportError(.expectedData(idx))
      return nil
    }
    idx += 1 // skip <
    
    var result = Dictionary<T, Any?>()

    while idx < buffer.count {
      guard skipComments() else {
        if reportError(.dictionaryNotClosed(idx)) { return nil }
        break
      }
      
      if buffer[idx] == tokens.closeDict {
        idx += 1
        break
      }
      
      /* read key property or identifier */
      guard let anyKey = parseDictionaryKey() else {
        if reportError(.invalidDictionaryKey(idx)) { return nil }
        break
      }
      guard let key = anyKey as? T else {
        if reportError(.invalidDictionaryKey(idx)) { return nil }
        break
      }

      /* The following parses:  (comment|space)* '=' (comment|space)* */
      guard skipComments() else {
        if reportError(.dictionaryAssignmentMissing(idx)) { return nil }
        break
      }
      if buffer[idx] != tokens.dictAssignment {
        if reportError(.dictionaryAssignmentMissing(idx)) { return nil }
      }
      else {
        idx += 1 // skip =
      }
      guard skipComments() else {
        if reportError(.dictionaryValueMissing(idx)) { return nil }
        break
      }
      
      /* read value property */
      
      if allowNilValues && parseNil() {
        result[key] = nil
      }
      else {
        guard let value = parseProperty() else {
          if reportError(.dictionaryValueMissing(idx)) { return nil }
          break
        }
        
        result[key] = value
      }
      
      /* read trailing ';' if available */
      guard skipComments() else {
        if reportError(.dictionaryNotClosed(idx)) { return nil }
        break
      }
      
      if buffer[idx] == tokens.dictPairSeparator {
        idx += 1 // skip ;
      }
      else { /* no ; at end of pair, only allowed at end of dictionary */
        if buffer[idx] != tokens.closeDict {
          if reportError(.dictionaryAssignmentNotTerminated(idx)) {
            return nil
          }
        }
      }
    }
    
    return result
  }
  
  func parseArray() -> [ Any? ]? {
    guard skipComments() else {
      _ = reportError(.expectedArray(idx))
      return nil
    }
    
    guard buffer[idx] == tokens.openArray else {
      _ = reportError(.expectedArray(idx))
      return nil
    }
    idx += 1 // skip (
    
    var result = [ Any? ]()
    
    while idx < buffer.count {
      guard skipComments() else {
        if reportError(.arrayNotClosed(idx)) { return nil }
        break
      }
      
      if buffer[idx] == tokens.closeArray {
        idx += 1
        break
      }
      
      if allowNilValues && parseNil() {
        result.append(nil)
      }
      else {
        guard let value = parseProperty() else {
          if reportError(.arrayNotClosed(idx)) { return nil }
          continue
        }
        result.append(value)
      }
      
      guard skipComments() else {
        if reportError(.arrayNotClosed(idx)) { return nil }
        break
      }

      if buffer[idx] == tokens.arraySeparator { // Note: we allow trailing
        idx += 1 // skip ;
      }
      else { /* no ; at end of pair, only allowed at end of dictionary */
        if buffer[idx] != tokens.closeArray {
          if reportError(.arrayNotClosed(idx)) { return nil }
        }
      }
    }
    
    return result
  }
  
  
  // MARK: - Position
  
  @inline(__always)
  func move(to pos: Int) -> Bool {
    idx = pos
    return idx < buffer.count
  }
  
  // MARK: - Classes

  func consume(_ s: String) -> Bool {
    let utf8  = s.utf8
    let count = utf8.count
    guard idx + count <= buffer.count else { return false }
    
    var pos = idx
    for c in utf8 {
      guard buffer[pos] == c else { return false }
      pos += 1
    }
    
    idx += count
    return true
  }

  @inline(__always)
  func isWhitespace(_ c: UInt8) -> Bool {
    return c <= C.space // for our purposes ...
  }
  
  @inline(__always)
  func isBreakChar(_ c: UInt8) -> Bool {
    guard !isWhitespace(c) else { return true }
    switch c {
      case C.tab, C.space, C.nl, C.cr, C.equal,
           C.equal, C.semicolon, C.comma,
           C.lbrace, C.lparen, C.dquote, C.lt,
           C.dot, C.colon,
           C.rparen, C.rbrace:
        return true
      default:
        return false
    }
  }
  
  @inline(__always)
  func isIDChar(_ c: UInt8) -> Bool {
    return c == C.dot || !isBreakChar(c)
  }

  @inline(__always)
  func isBreakChar(_ c: UInt8, by offset: Int) -> Bool {
    if idx + offset >= buffer.count { return true } // break on EOF
    return isBreakChar(c)
  }

  @inline(__always)
  func valueOfHexChar(_ c: UInt8) -> UInt8? {
    switch c {
      case C.n0...C.n9: return c - C.n0
      case C.upper_A...C.upper_F: return c - 55
      case C.lower_a...C.lower_f: return c - 87
      default: return nil
    }
  }

  @inline(__always)
  func isHexDigit(_ c: UInt8) -> Bool {
    switch c {
      case C.n0...C.n9, C.upper_A...C.upper_F, C.lower_a...C.lower_f:
        return true
      default: return false
    }
  }

  public enum PropertyListParseError : Swift.Error {
    case commentNotClosed                 (Int)
    case expectedIdentifier               (Int)
    case expectedKeyPathIdentifier        (Int)
    case expectedQuotedString             (Int)
    case expectedData                     (Int)
    case expectedDictionary               (Int)
    case expectedArray                    (Int)
    case expectedDigit                    (Int)
    case couldNotDecodeString             (Int)
    case escapeInQuoteNotFinished         (Int)
    case quotedStringNotClosed            (Int)
    case malformedData                    (Int)
    case invalidDictionaryKey             (Any)
    case dictionaryNotClosed              (Int)
    case dictionaryAssignmentMissing      (Int)
    case dictionaryValueMissing           (Int)
    case dictionaryAssignmentNotTerminated(Int)
    case arrayNotClosed                   (Int)
    case arraySeparatorMissing            (Int)
  }
  
  public struct Syntax {
    public let stringQuote       : UInt8
    public let stringQuote2      : UInt8
    public let stringEscape      : UInt8
    public let openDict          : UInt8
    public let closeDict         : UInt8
    public let dictAssignment    : UInt8
    public let dictPairSeparator : UInt8
    public let openArray         : UInt8
    public let closeArray        : UInt8
    public let arraySeparator    : UInt8
    public let openData          : UInt8
    public let closeData         : UInt8

    public init(stringQuote       : UInt8 = 34,  // C.dquote,
                stringQuote2      : UInt8 = 39,  // C.quote,
                stringEscape      : UInt8 = 92,  // C.backslash,
                openDict          : UInt8 = 123, // C.lbrace,
                closeDict         : UInt8 = 125, // C.rbrace,
                dictAssignment    : UInt8 = 61,  // C.equal,
                dictPairSeparator : UInt8 = 59,  // C.semicolon,
                openArray         : UInt8 = 40,  // C.lparen,
                closeArray        : UInt8 = 41,  // C.rparen,
                arraySeparator    : UInt8 = 44,  // C.comma,
                openData          : UInt8 = 60,  // C.lt,
                closeData         : UInt8 = 62)  // C.gt)
    {
      self.stringQuote       = stringQuote
      self.stringQuote2      = stringQuote2
      self.stringEscape      = stringEscape
      self.openDict          = openDict
      self.closeDict         = closeDict
      self.dictAssignment    = dictAssignment
      self.dictPairSeparator = dictPairSeparator
      self.openArray         = openArray
      self.closeArray        = closeArray
      self.arraySeparator    = arraySeparator
      self.openData          = openData
      self.closeData         = closeData
    }
  }
}

fileprivate enum C {
  static let n0        : UInt8 = 48
  static let n9        : UInt8 = 57
  static let upper_A   : UInt8 = 65
  static let upper_F   : UInt8 = 70
  static let upper_Y   : UInt8 = 89
  static let upper_N   : UInt8 = 78
  static let lower_a   : UInt8 = 97
  static let lower_f   : UInt8 = 102
  static let lower_n   : UInt8 = 110
  static let lower_r   : UInt8 = 114
  static let lower_t   : UInt8 = 116
  static let slash     : UInt8 = 47
  static let backslash : UInt8 = 92
  static let plus      : UInt8 = 43
  static let minus     : UInt8 = 45
  static let star      : UInt8 = 42
  static let space     : UInt8 = 32
  static let nl        : UInt8 = 10
  static let cr        : UInt8 = 13
  static let tab       : UInt8 = 9
  static let equal     : UInt8 = 61
  static let colon     : UInt8 = 58
  static let semicolon : UInt8 = 59
  static let comma     : UInt8 = 44
  static let lbrace    : UInt8 = 123
  static let rbrace    : UInt8 = 125
  static let lparen    : UInt8 = 40
  static let rparen    : UInt8 = 41
  static let dquote    : UInt8 = 34
  static let quote     : UInt8 = 39
  static let lt        : UInt8 = 60
  static let gt        : UInt8 = 62
  static let dot       : UInt8 = 46
}

internal extension Dictionary {
  
  func compactMapValues<T>(_ transform: ( Value ) throws -> T?) rethrows
       -> [ Key : T ]
  {
    var result: [ Key : T ] = [:]
    result.reserveCapacity(capacity)
    
    for (key, value) in self {
      guard let transformed = try transform(value) else { continue }
      result[key] = transformed
    }
    return result
  }
}
