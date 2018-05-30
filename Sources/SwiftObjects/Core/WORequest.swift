//
//  WORequest.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import struct Foundation.CharacterSet
import struct Foundation.URLComponents

open class WORequest : WOMessage {
  
  public static let SessionIDKey  = "wosid"
  public static let FragmentIDKey = "wofid"
  
  public let uri    : String
  public let method : String
  
  public init(method      : String, uri: String,
              httpVersion : Version  = Version(major: 1, minor: 1),
              headers     : Headers  = Headers(),
              contents    : Content? = nil)
  {
    self.method = method
    self.uri    = uri
    
    super.init(httpVersion: httpVersion, headers: headers, contents: contents)
    
    processURL()
  }
  
  open var defaultFormValueEncoding : String.Encoding = .utf8
  open var browserLanguages : [ String ]? {
    // TODO: implement me (accept-languages)
    return nil
  }

  // TODO:
  // URI components
  // WEClientCapabilities
  // corsHeaders, startTimeStampInMS
  
  open var adaptorPrefix   : String? { return nil }
  
  open var applicationName : String?
  
  /**
   * Returns the request-handler key associated with the request. This is
   * usually the second part of the URL, eg:
   *
   *     /HellWorld/wa/MyPage/doIt
   *
   * The request-handler key is 'wa' (and is mapped to the
   * WODirectActionRequestHandler in WOApplication).
   *
   * Note: this method is considered 'almost' deprecated. Lookups are now
   * usually done "GoStyle" (lookupName on the WOApp will be used to discover
   * the WORequestHandler).
   *
   * @return the request handler key part of the URL, eg 'wo' or 'wa'
   */
  open var requestHandlerKey  : String?
  
  /**
   * This is the part of the URL which follows the requestHandlerKey(), see
   * the respective method for details.
   *
   * @return the request handler path part of the URL, eg 'MyPage/doIt'
   */
  open var requestHandlerPath : String?
  
  /**
   * This is the part of the URL which follows the requestHandlerKey(), see
   * the respective method for details.
   */
  open var requestHandlerPathArray : [ String ] = []
  
  func processURL() {
    guard !uri.isEmpty else { return }
    
    var luri : String
    if let parts = URLComponents(string: uri) {
      luri = parts.path
    }
    else {
      luri = uri
    }
    
    /* cut off adaptor prefix */
    if let s = adaptorPrefix, !s.isEmpty, luri.hasPrefix(s) {
      let idx = luri.index(luri.startIndex, offsetBy: s.count)
      luri = String(luri[idx..<luri.endIndex])
    }
    
    let urlParts      = luri.components(separatedBy: "/")
    var charsConsumed = 0
    
    if urlParts.count > 1 {
      let s = urlParts[1]
      charsConsumed += s.count + 1
      if !s.isEmpty {
        applicationName = s
      }
    }
    if urlParts.count > 2 {
      let s = urlParts[2]
      charsConsumed += s.count + 1
      requestHandlerKey = s
    }
    
    var idx = luri.index(luri.startIndex, offsetBy: charsConsumed)
    if idx < luri.endIndex, luri[idx] == "/" {
      idx = luri.index(after: idx)
    }
    if idx < luri.endIndex {
      requestHandlerPath = String(luri[idx..<luri.endIndex])
      if urlParts.count > 3 {
        requestHandlerPathArray = Array(urlParts[3..<urlParts.endIndex])
      }
    }
    else {
      requestHandlerPath = ""
    }
  }
  
  
  // MARK: - Form Values
  
  var _formValues : [ String : [ Any ] ]? = nil
  open var formValues : [ String : [ Any ] ] {
    if let v = _formValues { return v }
    let v = parseFormValues()
    _formValues = v
    return v
  }

  open var hasFormValues : Bool {
    return formValues.count > 0
  }
  
  open var formValueKeys : [ String ] {
    return Array(formValues.keys)
  }
  
  open func formValue(for key: String) -> Any? {
    return formValues(for: key)?.first
  }
  open func formValues(for key: String) -> [ Any ]? {
    return formValues[key]
  }

  open func stringFormValue(for key: String) -> String? {
    guard let fv = formValue(for: key) else { return nil }
    return (fv as? String) ?? String(describing: fv)
  }
  
  func parseFormValues() -> [ String : [ Any ] ] {
    var rawValues = [ String : [ Any ]]()
    
    func extractQueryParameters(from string: String) {
      guard let url = URLComponents(string: string),
            let qs  = url.query, !qs.isEmpty else {
        return
      }
      // Unfortuntately queryItems do not decode `+` :-/
      
      for pair in qs.split(separator: "&") {
        let splitPair = pair.split(separator: "=", maxSplits: 1,
                                   omittingEmptySubsequences: false)
            .map { $0.replacingOccurrences(of: "+", with: " ") }
            .map { $0.removingPercentEncoding ?? "??" } // TODO
        let name  = splitPair[0]
        let value = splitPair.count > 1 ? splitPair[1] : nil
        
        if let value = value {
          if rawValues[name]?.append(value) == nil {
            rawValues[name] = [ value ]
          }
        }
        else if rawValues[name] == nil {
          rawValues[name] = []
        }
      }
    }
    
    extractQueryParameters(from: uri)
    
    if method == "POST", let ct = header(for: "Content-Type"),
       ct.lowercased().hasPrefix("application/x-www-form-urlencoded"),
       let body = contentString, !body.isEmpty
    {
      extractQueryParameters(from: "?" + body)
    }
    
    // TODO: port the Zope style processing via `:` parameters.
    
    return rawValues
  }
  
  
  // MARK: - Cookie Values
  
  override open var cookies : [ WOCookie ] {
    if let c = _cookies { return c }
    
    var cookies = [ WOCookie ]()
    for h in headers(for: "Cookie") {
      /*
       * Note: this is loading using the 'Cookie' syntax. That is, ';' separates
       *       individual cookies, not cookie options.
       */
      let cs = h.components(separatedBy: ";")
      for s in cs {
        guard !s.isEmpty else { continue }
        guard let cookie = WOCookie.parse(string: s) else { continue }
        cookies.append(cookie)
      }
    }
    
    _cookies = cookies
    return cookies
  }

  open func cookieValues(for key: String) -> [ String ] {
    return cookies.filter { $0.name == key }.map { $0.value }
  }
  open func cookieValue(for key: String) -> String? {
    return cookies.first(where: { $0.name == key })?.value
  }

  open var cookieValues : [ String : [ String ] ] {
    var values = [ String : [ String ] ]()
    
    for cookie in cookies {
      if values[cookie.name]?.append(cookie.value) == nil {
        values[cookie.name] = [ cookie.value ]
      }
    }
    
    return values
  }
  
  
  // MARK: - Session / Fragment IDs
  
  /**
   * Returns a session-ID which is embedded in a form value or cookie of the
   * request. This also checks whether the session id is empty or has the
   * special 'nil' value (can be used to explicitly reset a session-id).
   *
   * Example:
   *
   *     /MyApp/wa/MyPage/doIt?wosid=3884726736474
   *
   * This will return '3884726736474' as the session-id.
   *
   * @return the session-id or null if none could be found
   */
  open var sessionID : String? {
    var v : String? = stringFormValue(for: WORequest.SessionIDKey)
    v = v?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    if let vv = v, vv.isEmpty || vv == "-" { v = nil }
    
    if v == nil {
      for vv in cookieValues(for: WORequest.SessionIDKey) {
        let s = vv.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if s.isEmpty || s == "-" || s == "nil" { continue }
        v = s
        break
      }
    }
    
    if let vv = v, vv == "nil" { v = nil }
    return v
  }
  
  open var isSessionIDInRequest : Bool {
    return sessionID != nil
  }
  
  /**
   * Returns the fragment id in the request. A fragment is a named part of the
   * page which should be rendered. The fragment-id will be set in the context
   * and then considered by the response generation. You usually don't need to
   * call this method in usercode.
   *
   * Example:
   *
   *     /MyApp/wa/MyPage/doIt?wofid=tasklist
   *
   * This will return 'tasklist' as the fragment-id.
   *
   * @return the fragmentID or null if none could be found
   */
  open var fragmentID : String? {
    guard var s = stringFormValue(for: WORequest.FragmentIDKey) else {
      return nil
    }
    s = s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return s.isEmpty ? nil : s
  }

  open var isFragmentIDInRequest : Bool {
    return fragmentID != nil
  }
  
  
  // MARK: - Form Actions
  
  /**
   * Checks whether the form parameters contain Zope style :action form values.
   */
  open var formAction : String? {
    for key in formValueKeys {
      let count = key.count
      guard count > 7 else { continue }
      
      if key.hasSuffix(":action") {
        let endIndex = key.index(key.endIndex, offsetBy: -7)
        return String(key[key.startIndex..<endIndex])
      }
      else if key.hasSuffix(":action.x") { // image submits (coordinates)
        let endIndex = key.index(key.endIndex, offsetBy: -9)
        return String(key[key.startIndex..<endIndex])
      }
    }
    return nil
  }
  
  
  // MARK: - KVC
  
  override open func value(forKey k: String) -> Any? {
    switch k {
      case "uri":                      return uri
      case "method":                   return method
      case "defaultFormValueEncoding": return defaultFormValueEncoding
      case "browserLanguages":         return browserLanguages
      case "adaptorPrefix":            return adaptorPrefix
      case "applicationName":          return applicationName
      case "requestHandlerKey":        return requestHandlerKey
      case "requestHandlerPath":       return requestHandlerPath
      case "requestHandlerPathArray":  return requestHandlerPathArray
      case "formValues":               return formValues
      case "hasFormValues":            return hasFormValues
      case "formValueKeys":            return formValueKeys
      case "cookieValues":             return cookieValues
      case "sessionID":                return sessionID
      case "isSessionIDInRequest":     return isSessionIDInRequest
      case "fragmentID":               return fragmentID
      case "isFragmentIDInRequest":    return isFragmentIDInRequest
      case "formAction":               return formAction
      default: return super.value(forKey: k)
    }
  }
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    ms += " "
    ms += method
    ms += " "
    ms += uri
    
    super.appendToDescription(&ms)
    
    // TODO: implement me
  }
}
