//
//  WONIORequest.swift
//  SwiftObjects
//
//  Created by Helge Hess on 21.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import NIO
import NIOHTTP1

final class WONIORequest : WORequest {
  
  let channel : Channel
  
  init(channel     : Channel,
       method      : String, uri: String,
       httpVersion : Version  = Version(major: 1, minor: 1),
       headers     : Headers  = Headers(),
       contents    : Content? = nil)
  {
    self.channel = channel
    super.init(method: method, uri: uri,
               httpVersion: httpVersion, headers: headers, contents: contents)
  }
}

extension HTTPMethod {

  #if swift(>=5) // NIO 2 API - the excellence of open enums ... Thanks Swift!
  var woMethod : String {
    switch self {
      case .GET:            return "GET"
      case .PUT:            return "PUT"
      case .ACL:            return "ACL"
      case .HEAD:           return "HEAD"
      case .POST:           return "POST"
      case .COPY:           return "COPY"
      case .LOCK:           return "LOCK"
      case .MOVE:           return "MOVE"
      case .BIND:           return "BIND"
      case .LINK:           return "LINK"
      case .PATCH:          return "PATCH"
      case .TRACE:          return "TRACE"
      case .MKCOL:          return "MKCOL"
      case .MERGE:          return "MERGE"
      case .PURGE:          return "PURGE"
      case .NOTIFY:         return "NOTIFY"
      case .SEARCH:         return "SEARCH"
      case .UNLOCK:         return "UNLOCK"
      case .REBIND:         return "REBIND"
      case .UNBIND:         return "UNBIND"
      case .REPORT:         return "REPORT"
      case .DELETE:         return "DELETE"
      case .UNLINK:         return "UNLINK"
      case .CONNECT:        return "CONNECT"
      case .MSEARCH:        return "MSEARCH"
      case .OPTIONS:        return "OPTIONS"
      case .PROPFIND:       return "PROPFIND"
      case .CHECKOUT:       return "CHECKOUT"
      case .PROPPATCH:      return "PROPPATCH"
      case .SUBSCRIBE:      return "SUBSCRIBE"
      case .MKCALENDAR:     return "MKCALENDAR"
      case .MKACTIVITY:     return "MKACTIVITY"
      case .UNSUBSCRIBE:    return "UNSUBSCRIBE"
      case .SOURCE:         return "SOURCE"
      case .RAW(let value): return value
    }
  }
  #else // NIO 1 API
  var woMethod : String {
    switch self {
      case .GET:            return "GET"
      case .PUT:            return "PUT"
      case .ACL:            return "ACL"
      case .HEAD:           return "HEAD"
      case .POST:           return "POST"
      case .COPY:           return "COPY"
      case .LOCK:           return "LOCK"
      case .MOVE:           return "MOVE"
      case .BIND:           return "BIND"
      case .LINK:           return "LINK"
      case .PATCH:          return "PATCH"
      case .TRACE:          return "TRACE"
      case .MKCOL:          return "MKCOL"
      case .MERGE:          return "MERGE"
      case .PURGE:          return "PURGE"
      case .NOTIFY:         return "NOTIFY"
      case .SEARCH:         return "SEARCH"
      case .UNLOCK:         return "UNLOCK"
      case .REBIND:         return "REBIND"
      case .UNBIND:         return "UNBIND"
      case .REPORT:         return "REPORT"
      case .DELETE:         return "DELETE"
      case .UNLINK:         return "UNLINK"
      case .CONNECT:        return "CONNECT"
      case .MSEARCH:        return "MSEARCH"
      case .OPTIONS:        return "OPTIONS"
      case .PROPFIND:       return "PROPFIND"
      case .CHECKOUT:       return "CHECKOUT"
      case .PROPPATCH:      return "PROPPATCH"
      case .SUBSCRIBE:      return "SUBSCRIBE"
      case .MKCALENDAR:     return "MKCALENDAR"
      case .MKACTIVITY:     return "MKACTIVITY"
      case .UNSUBSCRIBE:    return "UNSUBSCRIBE"
      case .RAW(let value): return value
    }
  }
  #endif // NIO 1
}
