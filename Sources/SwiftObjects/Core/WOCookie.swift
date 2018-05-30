//
//  WOCookie.swift
//  SwiftObjects
//
//  Created by Helge Hess on 28.05.18.
//

import Foundation

/**
 * Represents an HTTP cookie.
 *
 * Use the addCookie() method of WOResponse to add a setup cookie, e.g.:
 *
 *     response.addCookie(WOCookie("myCookie", "Hello World"))
 *
 * To check for cookies coming in, use cookieValueForKey() or
 * cookieValuesForKey() of WORequest, eg:
 *
 *     print("Cookie:", _rq.cookieValue(for: "myCookie"))
 *
 * Remember that browsers limit the size and the number of cookies per site.
 *
 * To pass a cookie between hosts you can use the domain, eg:
 *
 *     domain=.zeezide.com
 *
 * will deliver the cookie to:
 *
 *     shop.zeezide.com
 *     crm.zeezide.com
 *     etc
 *
 * Note: if the path is not set, the request path will be used! This is usually
 *       not what you want.
 *
 * Outdated iunfo:
 * http://www.ietf.org/rfc/rfc2109.txt
 * http://www.faqs.org/rfcs/rfc2965.html (only implemented by Opera?)
 */
public struct WOCookie : SmartDescription {
  
  let log = WOPrintLogger.shared
  
  public var name    : String    /* name of cookie, eg 'wosid'   */
  public var value   : String {  /* value of cookie, eg '283873' */
    didSet {
      if value.hasPrefix("$") {
        WOPrintLogger.shared.warn("Cookie value may not start w/ $:", value)
      }
    }
  }
  
  public var path    : String?   /* path the cookie is valid for, eg '/MyApp' */
  public var domain  : String? { /* domain the cookie is valid for (.com) */
    didSet {
      if domain?.hasPrefix(".") ?? false {
        WOPrintLogger.shared.warn("Cookie domain may not start w/ .:", domain)
      }
    }
  }
  
  /**
   * Sets the 'expires' date for the cookie, see RFC 2109. This is deprecated,
   * use setTimeOut (Max-Age) instead.
   *
   * @param _date - the Date when the cookie expires
   */
  public var date    : Date?
  
  /**
   * Sets the cookie-timeout aka the 'Max-Age' attribute of RFC 2109.
   *
   * - if the value is < 0, we do not generate a Max-Age (hence, no to)
   * - if the value is 0, this tells the browser to expire the cookie
   * - if the value is < 0, the browser will remove the cookie
   *
   * @param _date
   */
  public var timeout : Int?      /* in seconds (nil == do not expire) */
  
  public var isSecure: Bool      /* whether cookie requires an HTTPS connection */

  public init(name: String, value: String,
              path: String? = nil, domain: String? = nil, date: Date? = nil,
              timeout: Int? = nil, isSecure: Bool = false)
  {
    self.name     = name
    self.value    = value
    self.path     = path
    self.domain   = domain
    self.date     = date
    self.timeout  = timeout
    self.isSecure = isSecure
  }
  
  
  // MARK: - generating HTTP cookie
  
  /**
   * Returns the HTTP response representation of the cookie value, w/o the
   * header name ("cookie").
   *
   * @return the HTTP String representing the WOCookie
   */
  public var headerString : String {
    // FIXME: check whether any of this is 2018-up2date
    var sb = ""
    
    // TODO: do we need to escape the value?
    sb += name
    sb += "="
    sb += value
    sb += "; version=\"1\"" // v1 means RFC 2109
    
    if let s  = path   { sb += "; path=\(s)"   }
    if let s  = domain { sb += "; domain=\(s)" }
    if let to = timeout, to >= 0 { sb += "; Max-Age=\(to)" }
    
    if let _ = date {
      // TBD: Wdy, DD-Mon-YY HH:MM:SS GMT
      log.warn("WOCookie does not yet support expires, and you should use " +
               "setTimeOut() anyways (aka Max-Age)");
    }
    else if timeout == nil {
      /* A convenience to improve browser compat, straight from:
       *   http://wp.netscape.com/newsref/std/cookie_spec.html
       * This helps Safari3 forget cookies (Max-Age: 0 doesn't seem to affect
       * it).
       */
      sb += "; expires=Wednesday, 09-Nov-99 23:12:40 GMT"
    }
    
    if isSecure { sb += "; secure" }
    
    return sb
  }
  
  
  /* parsing cookies */
  
  public static func parse(string s: String) -> WOCookie? {
    let log = WOPrintLogger.shared
    
    guard let vidx = s.index(of: "=") else {
      log.warn("got invalid cookie value: '\(s)'")
      return nil
    }
    
    let name  = String(s[s.startIndex..<vidx])
    var value = String(s[s.index(after: vidx)..<s.endIndex])
    
    // TODO: process escaping
    
    if value.index(of: ";") == nil {
      return WOCookie(name: name, value: value)
    }
    
    /* process options */
    
    let opts = value.components(separatedBy: ";")
    
    var domain   : String?
    var path     : String?
    var isSecure : Bool = false
    
    var isFirst = true
    for opt in opts {
      if isFirst { isFirst = false; value = opt }
      
      let sidx = opt.startIndex, eidx = opt.endIndex
      if opt.hasPrefix("domain=") {
        domain = String(opt[opt.index(sidx, offsetBy: 7)..<eidx])
      }
      else if opt.hasPrefix("path=") {
        path = String(opt[opt.index(sidx, offsetBy: 5)..<eidx])
      }
      else if opt == "secure" {
        isSecure = true
      }
      else {
        log.warn("unknown cookie option:", opt, "in:", s)
      }
    }
    
    return WOCookie(name: name, value: value,
                    path: path, domain: domain, isSecure: isSecure)
  }
  
  
  // MARK: - Description
  
  public func appendToDescription(_ ms: inout String) {
    ms += " \(name)=\(value)"
    
    if let s = path   { ms += " path=\(s)"   }
    if let s = domain { ms += " domain=\(s)" }

    if let timeout = timeout {
      ms += " to=\(timeout)s"
    }
    else { ms += " delete-cookie" }

    if isSecure { ms += " secure" }
  }
  
  
  /* utility */
  
  public static func addCookieInfos(_ cookies : [ WOCookie ],
                                    to sb: inout String)
  {
    var isFirst = true
    
    for cookie in cookies {
      if isFirst { isFirst = false }
      else { sb += "," }
      
      if cookie.timeout == nil { // expire
        sb += "-"
        sb += cookie.name
      }
      else {
        sb += cookie.name
        sb += "="
        if cookie.value.count < 12 {
          sb += cookie.value
        }
        else {
          let s = cookie.value
          sb += s[s.startIndex..<s.index(s.startIndex, offsetBy: 10)]
          sb += ".."
        }
      }
    }
  }
}
