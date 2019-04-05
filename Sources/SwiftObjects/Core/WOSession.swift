//
//  WOSession.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import struct Foundation.TimeInterval
import struct Foundation.Date
import NIOConcurrencyHelpers
import SwiftHash
import Runtime

/**
 * Object used to store values between page invocations.
 * Also used for saving pages for component actions.
 *
 * THREAD: this object should only be accessed from one thread at a time.
 *         Locking should be ensured by the WOSessionStore checkout/in
 *         mechanism.
 */
open class WOSession : WOLifecycle, WOResponder, SmartDescription,
                       ExtraVariables,
                       KeyValueCodingType, MutableKeyValueCodingType
{
  public let log = WOPrintLogger.shared
  
  public let sessionID          : String
  public var storesIDsInURLs    = true
  public var storesIDsInCookies = false
  public var timeout            : TimeInterval = 3600
  public var variableDictionary = [ String : Any ]()

  public private(set) var isTerminating = false
  
  open var languages : [ String ]? = nil
  
  required public init() {
    sessionID = WOSession.createSessionID()
  }
  
  private static var snIdCounter = Atomic(value: 0)
  
  static func createSessionID() -> String {
    // TODO: better place in app object to allow for 'weird' IDs ;-), like
    //       using a session per basic-auth user
    // FIXME: dangerous non-sense, use properly secured SID :-)
    let now = Int(Date().timeIntervalSince1970)
    let cnt = snIdCounter.add(1)
    let baseString = "\txyyzSID\n\(now)\t\(cnt)\tRANDOMWOULDBECOOL"
    return SwiftHash.MD5(baseString)
  }
  
  
  // MARK: - Livecycle
  
  public private(set) var isAwake : Bool = false
  
  /**
   * Requests the termination of the WOSession. This is what you would call in
   * a logout() method to finish a session.
   */
  open func terminate() {
    isTerminating = true
  }
  
  open func awake() {
  }
  open func sleep() {
  }
  
  /**
   * This is called by WOApp.initializeSession() or WOApp.restoreSessionWithID()
   * to prepare the session for a request/response cycle.
   * <p>
   * The method calls the awake() method which should be used by client code
   * for per-request state setup.
   *
   * @param _ctx - the WOContext the session is active in
   */
  internal func awake(in context: WOContext) {
    guard !isAwake else { return }
    awake()
    isAwake = true
  }
  
  /**
   * Called by WOApp.handleRequest() to teardown sessions before they get
   * archived.
   *
   * @param _ctx - the WOContext representing the current transaction
   */
  internal func sleep(in context: WOContext) {
    guard isAwake else { return }
    sleep()
    isAwake = false
  }
  
  func addSessionIDCookie(to response: WOResponse, in context: WOContext) {
    // TODO
  }
  
  
  // MARK: - Responder
  
  /**
   * This starts the takeValues phase of the request processing. In this phase
   * the relevant objects fill themselves with the state of the request before
   * the action is invoked.
   *
   * This method is called by WOApp.takeValuesFromRequest() if a session is
   * active in the context.
   */
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    guard let senderID = context.senderID, !senderID.isEmpty else {
      /* no element URL is available */
      guard let page = context.page else {
        context.log.info("got no page in context to push values to?", self)
        return
      }
      
      context.enterComponent(page)
      defer { context.leaveComponent(page) }
      
      try page.takeValues(from: request, in: context)
      return
    }
    
    // regular component action
    
    if request.method == "GET" && !request.uri.contains("?") {
      /* no form content to apply */
      // TODO: we should run the takeValues nevertheless to clear values?
      // Probably!
      return
    }
    
    guard let page = context.page else {
      context.log.info("got no page in context to push values to?", self)
      return
    }
    
    context.enterComponent(page)
    defer { context.leaveComponent(page) }
    
    try page.takeValues(from: request, in: context)
  }
  
  /**
   * This triggers the invokeAction phase of the request processing. In this
   * phase the relevant objects got their form values pushed in and the action
   * is ready to be performed.
   *
   * This is called by WOApp.invokeAction() if a session is active in the
   * context.
   */
  open func invokeAction(for request : WORequest,
                         in  context : WOContext) throws -> Any?
  {
    guard let page = context.page else {
      context.log.info("got no page in context to invoke the action on?", self)
      return nil
    }

    context.enterComponent(page)
    defer { context.leaveComponent(page) }

    return try page.invokeAction(for: request, in: context) ?? page
  }
  
  /**
   * This is called by the WOApp.appendToResponse() if the context has a
   * session set.
   * It sets various session specific features and then triggers the context
   * to render to the response.
   *
   * Note: this is currently not called for Go-based lookups. Go-lookups are
   * handled in the WOApp.handleRequest method which also adds the session-id
   * cookie.
   *
   * @param _r   - the WOResponse object to generate to
   * @param _ctx - the WOContext the generation takes place in
   */
  open func append(to response: WOResponse, in context: WOContext) throws {
    // TODO
    
    /* HTTP/1.1 caching directive, prevents browser from caching dyn pages */
    if context.application.isPageRefreshOnBacktrackEnabled {
      if let ct = response.header(for: "Content-Type"), ct.contains("html") {
        response.disableClientCaching()
      }
    }
    
    context.deleteAllElementIDComponents()
    if let page = context.page {
      context.enterComponent(page)
      defer { context.leaveComponent(page) }
      
      try page.append(to: response, in: context)
    }
    
    if storesIDsInCookies {
      addSessionIDCookie(to: response, in: context)
    }
    
    // TODO: record statistics
  }

  
  // MARK: - Page Cache
  
  var pageCache          = WOSessionPageCache()
  var permanentPageCache = WOSessionPageCache()
  
  /**
   * Restore a WOComponent from the session page caches. This first checks the
   * permanent and then the transient cache for the given ID.
   *
   * Remember that a ContextID identifies a certain state of the component. It
   * encapsulates the state the component had at rendering time. If a component
   * action is processed, we need to restore that state to properly process
   * component URLs.
   *
   * @param _ctxId - the ID of the context which resulted in the required page
   * @return null if the ID expired, or the stored WOComponent
   */
  open func restorePage(for contextID: String) -> WOComponent? {
    guard !contextID.isEmpty else { return nil }
    
    if let page = permanentPageCache.restorePage(for: contextID) {
      return page
    }
    if let page = pageCache.restorePage(for: contextID) {
      return page
    }
    return nil
  }
  
  /**
   * Returns the ID of the WOContext associated with the page. This just calls
   * `_page.context?.contextID`.
   *
   * @param _page - the page to retrieve the context id for
   * @return a context-id or null if no context was associated with the page
   */
  open func contextID(for page: WOComponent) -> String? {
    return page.context?.contextID
  }
  
  /**
   * Saves the given page in the page cache of the session. If the context-id of
   * the page is already in the permanent page cache, this will trigger
   * savePageInPermanentCache().
   *
   * All the storage is based on the context-id of the page as retrieved by
   * contextIDForPage() method.
   *
   * Note: this method is related to WO component actions which need to preserve
   * the component (/context) which generated a component action link.
   *
   * @param _page - the page which shall be preserved
   */
  open func savePage(_ page: WOComponent) {
    guard let ctxId = contextID(for: page) else { return }
    
    if permanentPageCache.containsContextID(ctxId) {
      return savePageInPermanentCache(page)
    }
    
    pageCache.savePage(page, for: ctxId)
  }
  
  /**
   * Saves the given page in the permant cache. The permanent cache is just a
   * separate which can be filled with user defined pages that should not be
   * expired. Its usually used in frame-tag contexts to avoid 'page expired'
   * issues. (check Google ;-)
   *
   * Note: this method is related to WO component actions which need to preserve
   * the component (/context) which generated a component action link.
   *
   * @param _page - the save to be stored in the permanent cache
   */
  open func savePageInPermanentCache(_ page: WOComponent) {
    guard let ctxId = contextID(for: page) else { return }
    permanentPageCache.savePage(page, for: ctxId)
  }

  
  // MARK: - KVC
  
  lazy var typeInfo = try? Runtime.typeInfo(of: type(of: self))
  
  open func takeValue(_ value : Any?, forKey k: String) throws {
    if variableDictionary[k] != nil {
      if let value = value { variableDictionary[k] = value }
      else { variableDictionary.removeValue(forKey: k) }
    }
    
    switch k {
      case "sessionID", "storesIDsInURLs", "storesIDsInCookies", "timeout",
           "variableDictionary", "isTerminating":
        return try handleTakeValue(value, forUnboundKey: k)
      case "languages":
        // TODO
        return try handleTakeValue(value, forUnboundKey: k)
      default: break
    }
    
    if let ti = typeInfo, let prop = try? ti.property(named: k) {
      var me = self // TBD
      if let value = value { try prop.zset(value: value,        on: &me) }
      else                 { try prop.zset(value: value as Any, on: &me) }
      return
    }
    
    variableDictionary[k] = value
  }
  
  open func value(forKey k: String) -> Any? {
    if let v = variableDictionary[k] { return v }
    
    switch k {
      case "sessionID":          return sessionID
      case "storesIDsInURLs":    return storesIDsInURLs
      case "storesIDsInCookies": return storesIDsInCookies
      case "isTerminating":      return isTerminating
      case "languages":          return languages
      default: break
    }
    
    guard let ti = typeInfo, let prop = try? ti.property(named: k) else {
      return handleQueryWithUnboundKey(k)
    }
    do {
      // if this is an optional, we wrap it again
      let v = try prop.zget(from: self)
      return v
    }
    catch {
      log.error("Failed to get KVC property:", k, error)
      return nil
    }
  }


  // MARK: - Description
  
  open func appendToDescription(_ ms: inout String) {
    ms += " id=\(sessionID) timeout=\(timeout)s"
  }
}

