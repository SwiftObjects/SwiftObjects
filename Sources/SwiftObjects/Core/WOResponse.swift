//
//  WOResponse.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

open class WOResponse : WOMessage, WOActionResults {
  
  // TODO: enableStreaming() (implement in NIO subclass)

  open   var status  = 200
  public let request : WORequest?
  
  public init(request: WORequest? = nil) {
    self.request = request
    
    super.init()
    
    setHeader("text/html; charset=utf-8", for: "Content-Type")
  }

  open func generateResponse() throws -> WOResponse {
    return self
  }
  
  open func disableClientCaching() {
    // TODO: add expires header
    // TODO: maybe add some etag which changes always?
    // TODO: check whether those are correct
    setHeader("no-cache", for: "Cache-Control")
    setHeader("no-cache", for: "Pragma")
  }
  
  
  // MARK: - KVC
  
  override open func value(forKey k: String) -> Any? {
    switch k {
      case "status":  return status
      case "request": return request
      default: return super.value(forKey: k)
    }
  }
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    ms += " status=\(status)"
    if let _ = request { ms += " has-rq" }
    super.appendToDescription(&ms)
  }
}
