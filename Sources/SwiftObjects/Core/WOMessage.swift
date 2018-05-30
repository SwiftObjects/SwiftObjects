//
//  WOMessage.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation
import NIOHTTP1 // This ties it to NIO, happy to remove this ;-)

/**
 * Abstract superclass of WORequest and WOResponse. Manages HTTP headers and
 * the entity content. Plus some extras (eg cookies and userInfo).
 *
 * Note:
 * Why do the write methods do not throw exceptions? Because 99% of the time
 * you write to a buffer and only a few times streaming is used (when delivering
 * large files / exports).
 * Using exceptions would result in a major complication of the rendering code.
 *
 * Note:
 * We do not use constructors for WOMessage initialization. Use the appropriate
 * init() methods instead.
 */
open class WOMessage : SmartDescription, KeyValueCodingType {
  
  public typealias Headers = NIOHTTP1.HTTPHeaders
  public typealias Version = NIOHTTP1.HTTPVersion
  public typealias Content = Foundation.Data
  
  // TODO: cookies, userInfo,
  //       contentEncoding, contentCoder, attributeCoder (NSTextCoder)
  //       - NSTextCoder may be different (already exist) in Swift

  open var headers     : Headers
  open var httpVersion : NIOHTTP1.HTTPVersion
  open var contents    : Content?
  public var _cookies : [ WOCookie ]? = nil
  
  open var contentEncoding : String.Encoding = .utf8
  
  public init(httpVersion : Version  = Version(major: 1, minor: 1),
              headers     : Headers  = Headers(),
              contents    : Content? = nil)
  {
    self.headers     = headers
    self.httpVersion = httpVersion
    self.contents    = contents
  }
  
  
  // MARK: - Headers
  
  open func setHeaders<T: Sequence>(_ values: T, for key: String)
              where T.Element == String
  {
    headers.remove(name: key)
    for value in values { headers.add(name: key, value: value )}
  }
  
  open func appendHeader(_ value: String, for key: String) {
    headers.add(name: key, value: value)
  }
  
  open func removeHeaders(for key: String) {
    headers.remove(name: key)
  }
  
  open func headers(for key: String) -> [ String ] {
    return headers[key]
  }
  
  open var headerKeys : [ String ] {
    return Array(Set(headers.lazy.map { $0.name }))
  }
  
  open func setHeader(_ value: String, for key: String) {
    headers.replaceOrAdd(name: key, value: value)
  }
  
  open func header(for key: String) -> String? {
    return headers[key].first
  }
  
  
  // MARK: - Contents
  
  open func appendContentCharacter(_ s: Character) throws {
    // FIXME
    try appendContentString(String(s))
  }

  open func appendContentData(_ data: Data) throws {
    if contents != nil { contents!.append(data) }
    else               { contents = data }
  }

  open func appendContentString(_ s: String) throws {
    guard let stringData = s.data(using: contentEncoding) else {
      assertionFailure("could not convert string to data: \(s)")
      return
    }
    
    if contents != nil { contents!.append(stringData) }
    else               { contents = stringData }
  }
  
  open func appendContentHTMLString(_ s: String) throws {
    // TODO: speedz
    try appendContentString(s.htmlEscaped)
  }
  
  /**
   * Returns the content of the message as a String. This uses the
   * `contentEncoding` to determine the necessary charset to
   * convert the content buffer into a String.
   *
   * @return the content of the message, or null
   */
  open var contentString : String? {
    set {
      if let s = newValue { contents = s.data(using: contentEncoding) }
      else                { contents = nil }
    }
    get {
      guard let contents = contents else { return nil }
      return String(data: contents, encoding: contentEncoding)
    }
  }
  
  open var contentAsDOMDocument : XMLDocument? {
    guard let contents = contents else { return nil }
    return try? XMLDocument(data: contents, options: [])
  }

  
  // MARK: - Tag based adding
  
  /**
   * Append the start of a begin tag with the given tagname. Sample:
   *
   *     response.appendBeginTag("a");
   *
   * generates:
   *
   *     <a>
   *
   * Note that it does not generate the closing bracket, this can be done by
   * invoking appendBeginTagEnd() (for container tags) or appendBeginTagClose()
   * (for empty tags).
   *
   * @param _tagName - the name of the tag which should be generated
   */
  open func appendBeginTag(_ name: String) throws {
    try appendContentCharacter("<")
    try appendContentString(name)
  }

  /**
   * Append the start of a begin tag with the given tagname and optionally a
   * set of attributes. Sample:
   *
   *     response.appendBeginTag("a", "target", 10)
   *
   * generates:
   *
   *     <a target="10"
   *
   * Note that it does not generate the closing bracket, this can be done by
   * invoking appendBeginTagEnd() (for container tags) or appendBeginTagClose()
   * (for empty tags).
   *
   * @param _tagName - the name of the tag which should be generated
   * @param _attrs   - a varargs list of key/value pairs
   */
  open func appendBeginTag(_ name: String, _ attributes : Any?...) throws {
    try appendBeginTag(name)
    
    for i in stride(from: 0, to: attributes.endIndex, by: 2) {
      guard let name = attributes[i] as? String else { continue } // TODO: fail
      let value = i + 1 < attributes.endIndex ? attributes[i + 1] : nil
      
      if let v = value {
        if let i = v as? Int {
          try appendAttribute(name, i)
        }
        else if let i = v as? String {
          try appendAttribute(name, i)
        }
        else { // hmm
          try appendAttribute(name, String(describing: v))
        }
      }
      else {
        try appendAttribute(name, nil)
      }
    }
  }

  /**
   * Appends the closing bracket '>' of a tag.
   *
   * @return an Exception if an error occured, null if everything is fine
   */
  open func appendBeginTagEnd() throws {
    try appendContentCharacter(">")
  }

  /**
   * Be careful with this one. Unless you are sure you want to generate XML,
   * you probably should use this construct instead:
   *
   *     response.appendBeginTagClose(context.closeAllElements())
   *
   * This method appends this string: `" />"`
   */
  open func appendBeginTagClose() throws {
    try appendContentString(" />")
  }
  
  /**
   * Commonly used like:
   *
   *     response.appendBeginTagClose(context.closeAllElements())
   *
   * This method appends this string: `" />"` if _doClose
   * is true, otherwise it adds `">"`.
   *
   * @param _doClose - whether or not the tag should be closed
   */
  open func appendBeginTagClose(_ doClose: Bool) throws {
    return doClose ? try appendContentString(" />")
                   : try appendContentCharacter(">")
  }

  open func appendEndTag(_ name: String) throws {
    try appendContentString("</\(name)>");
  }
  
  /**
   * This appends the given key/value attribute to the response. If the value
   * is null just the key is generated.
   * The method does not expand 'selected' to 'selected=selected', this is the
   * task of the dynamic element.
   *
   * @param _attrName
   * @param _attrValue
   */
  open func appendAttribute(_ name: String, _ value: String?) throws {
    if contents != nil {
      contents!.append(32)
      try appendContentString(name) // TODO: escape
      if let value = value {
        contents!.append(61)
        contents!.append(34)
        try appendContentHTMLAttributeValue(value)
        contents!.append(34)
      }
    }
    else {
      try appendContentCharacter(" ")
      try appendContentString(name) // TODO: escape
      if let value = value {
        try appendContentString("=\"")
        try appendContentHTMLAttributeValue(value)
        try appendContentCharacter("\"")
      }
    }
  }
  
  /**
   * This appends the given key/value attribute to the response.
   * Example:
   *
   *     response.appendAttribute("size", 12);
   *
   * Adding int-values is a bit faster, since they never need to be escaped.
   *
   * @param _attrName - the name of the attribute to add, eg "size"
   * @param _value    - the value of the attribute to add
   */
  open func appendAttribute(_ name: String, _ value: Int) throws {
    // FIXME: perf
    try appendAttribute(name, String(value))
  }

  open func appendContentHTMLAttributeValue(_ value: String) throws {
    try appendContentString(value) // TODO: escape
  }
  
  
  // MARK: - Cookie Values
  
  open var cookies : [ WOCookie ] {
    return _cookies ?? []
  }
  
  open func addCookie(_ cookie: WOCookie) {
    _ = cookies
    _cookies?.append(cookie)
  }
  open func removeCookie(_ cookie: WOCookie) {
    _ = cookies
    _cookies = _cookies?.filter { $0.name != cookie.name }
  }
  
  
  // MARK: - KVC
  
  open func value(forKey k: String) -> Any? {
    switch k {
      case "headers":              return headers
      case "httpVersion":          return httpVersion
      case "contents":             return contents
      case "contentEncoding":      return contentEncoding
      case "headerKeys":           return headerKeys
      case "contentString":        return contentString
      case "contentAsDOMDocument": return contentAsDOMDocument
      case "cookies":              return cookies
      default: return nil
    }
  }

  
  // MARK: - Description
  
  open func appendToDescription(_ ms: inout String) {
    ms += " #headers=\(headers.lazy.reduce(0, { last, _ in last + 1 }))"

    if let c = contents, !c.isEmpty {
      ms += " #content=\(c.count)"
    }
    ms += " http=\(httpVersion)"
    
    if let c = _cookies {
      ms += " #parsed-cookies=\(c.count)"
    }
  }
}

extension String {
  var htmlEscaped : String {
    let escapeMap : [ Character : String ] = [
      "<" : "&lt;", ">": "&gt;", "&": "&amp;", "\"": "&quot;"
    ]
    return map { escapeMap[$0] ?? String($0) }.reduce("", +)
  }
}
extension Substring {
  var htmlEscaped : String {
    let escapeMap : [ Character : String ] = [
      "<" : "&lt;", ">": "&gt;", "&": "&amp;", "\"": "&quot;"
    ]
    return map { escapeMap[$0] ?? String($0) }.reduce("", +)
  }
}

extension HTTPHeaders : KeyValueCodingType {

  public func value(forKey k: String) -> Any? {
    switch k {
      case "@count": return Int(self.lazy.reduce(0, { last, _ in last + 1 }))
      case "@keys":  return Array(Set(self.lazy.map { $0.name }))
      default:
        let a = self[k]
        guard !a.isEmpty else { return nil }
        return a.joined(separator:",")
    }
  }

}
