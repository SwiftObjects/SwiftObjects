//
//  WOCoreContext.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation
import NIOConcurrencyHelpers

/**
 * WOCoreContext
 *
 * The WOCoreContext is the context for one HTTP transaction, that is, one
 * request/response cycle. The core context provides access to the minimal set
 * of objects required for handling the requests, this includes the request and
 * the response.
 *
 * You will usually want to use a WOContext, which adds page tracking and
 * session handling.
 *
 * Its possible to assign additional, context-specific values to a context using
 * KVC. The object has an extraAttributes Map just like WOComponent or
 * WOSession.
 *
 * THREAD: WOCoreContext is not threadsafe, its supposed to be used from one
 *         thread only.
 */
public protocol WOCoreContext : class, SmartDescription {
  
  var log         : WOLogger { get }
  
  var application : WOApplication { get }
  
  /**
   * Returns the WORequest associated with the context. Its not strictly
   * required that a context has a request, e.g. if its just used for plain
   * rendering.
   */
  var request     : WORequest { get }

  /**
   * Returns the WOResponse associated with the context. Its not strictly
   * required that a context has a response, eg when its used to run just
   * the takeValues and/or invokeAction phases.
   */
  var response    : WOResponse { get }

  var contextID   : String     { get }

  var xmlStyleEmptyElements   : Bool { get set }
  var generateEmptyAttributes : Bool { get set }
  var closeAllElements        : Bool { get set }

  /**
   * Returns whether elements are allowed to collapse close tags, eg:
   * `<a name="abc"></a>` to `<a name="abc"/>`.
   *
   * You should only enable this for XML output.
   */
  var generateXMLStyleEmptyElements : Bool { get set }
}

open class WOCoreContextBase : WOCoreContext {

  open var log         : WOLogger { return application.log }

  public let application : WOApplication
  public let request     : WORequest
  open   var response    : WOResponse
  
  public let contextID   : String
  
  open   var xmlStyleEmptyElements   = false // do not generate <a/> but <a></a>
  open   var generateEmptyAttributes = false // generate selected=selected
  open   var closeAllElements        = true  // generate <br /> instead of <br>
  open   var generateXMLStyleEmptyElements = false
  
  private static var ctxIdCounter = Atomic(value: 0)

  public init(application: WOApplication, request: WORequest) {
    self.application = application
    self.request     = request
    self.response    = WOResponse(request: request)
    
    let stamp = Date().timeIntervalSince1970 - 1157999293 // magic
    self.contextID = "\(Int(stamp))x\(WOCoreContextBase.ctxIdCounter.add(1))"
  }

  
  // MARK: - Description
  
  open func appendToDescription(_ ms: inout String) {
    ms += " id="
    ms += contextID
  }
}
