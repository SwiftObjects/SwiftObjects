//
//  WOApplication.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation
import NIOConcurrencyHelpers
import Runtime

/**
 * This is the main entry class for Go web applications. You usually
 * start writing a Go app by subclassing this class. It then provides all
 * the setup of the Go infrastructure (creation of session and resource
 * managers, handling of initial requests, etc etc)
 *
 * The default name for the subclass is 'Application', alongside 'Context'
 * for a WOContext subclass and 'Session' for the app specific WOSession
 * subclass.
 *
 * A typical thing one might want to setup in an Application subclass is a
 * connection to the database.
 *
 * When you host within Jetty, this is a typical main() function for a Go based
 * web application:
 *
 *     public static void main(String[] args) {
 *         new WOJettyRunner(PackBack.class, args).run();
 *     }
 *
 * - FIXME: document it way more.
 * - FIXME: document how it works in a Servlet environment
 * - FIXME: document how properties are located and loaded
 *
 * ### Differences to WebObjects
 *
 * FIXME: document all the diffs ;-)
 *
 * #### QuerySession
 *
 * In addition to Context and Session subclasses, Go has the concept of a
 * 'QuerySession'. The baseclass is WOQuerySession and an application can
 * subclass this.
 * FIXME: document more
 *
 * #### Zope like Object Publishing
 *
 * FIXME: document all this. Class registry, product manager, root object,
 * renderer factory.
 *
 * Request handler processing can be turned on and off.
 *
 * #### pageWithName()
 *
 * In Go this supports component specific resource managers, not just the
 * global one. The WOApplication pageWithName takes this into account, it
 * is NOT the fallback root lookup (and thus can be used in all contexts).
 * It first checks the active WOComponent for the resource manager.
 */
open class WOApplication : WOLifecycle, WOResponder, WORequestDispatcher,
                           GoObjectRendererFactory, KeyValueCodingType
{
  
  public let log : WOLogger = WOPrintLogger(logLevel: .Log)
  
  let properties          = UserDefaults.standard
  var requestCounter      = Atomic(value: 0)
  var activeDispatchCount = Atomic(value: 0)
  
  open var contextClass      : WOContext.Type? = nil
  open var sessionClass      : WOSession.Type? = nil
  open var querySessionClass : WOQuerySession.Type = WOQuerySession.self
  
  var _name : String? = nil
  open var name : String {
    set { _name = newValue }
    get { return _name ?? UObject.getSimpleName(self) }
  }
  
  public init() {
    self.sessionStore = WOServerSessionStore()
    
    // TODO: setup resourceManager
    
    registerInitialRequestHandlers()
  }
  
  /**
   * This method registers the default request handlers, that is:
   *
   * - WODirectActionRequestHandler ('wa' and 'x')
   * - WOResourceRequestHandler ('wr', 'WebServerResources', 'Resources')
   * - WOComponentRequestHandler ('wo')
   */
  func registerInitialRequestHandlers() {
    let da = WODirectActionRequestHandler(application: self)
    registerRequestHandler(da, for: directActionRequestHandlerKey)
    registerRequestHandler(da, for: "x")
    defaultRequestHandler = da
    
    let ra = WOResourceRequestHandler(application: self)
    registerRequestHandler(ra, for: resourceRequestHandlerKey)
    registerRequestHandler(ra, for: "WebServerResources")
    registerRequestHandler(ra, for: "Resources")
    
    let ca = WOComponentRequestHandler(application: self)
    registerRequestHandler(ca, for: componentRequestHandlerKey)
  }
  
  
  // MARK: - Lifecycle
  
  /**
   * This method is called by handleRequest() when the application starts to
   * process a given request. Since it has no WOContext parameter its rather
   * useless :-)
   */
  open func awake() {
  }
  
  /**
   * The balancing method to awake(). Called at the end of the handleRequest().
   */
  open func sleep() {
  }
  
  
  // MARK: - Main Request Entry Point
  
  lazy var favicon : Data? = {
    return resourceManager?.dataForResourceNamed("favicon.ico", languages: [])
  }()
  
  open func dispatchRequest(_ request: WORequest) -> WOResponse {
    let rqId = requestCounter.add(1)
    _ = activeDispatchCount.add(1)
    defer { _ = activeDispatchCount.sub(1) }
    
    // TODO: port CORS stuff, OPTIONS
    
    guard let rh = requestHandler(for: request) else {
      log.error("Missing request handler for request:", request)
      let r = WOResponse(request: request)
      r.status = 500
      try? r.appendContentHTMLString("Missing request handler!")
      return r
    }
    
    var response : WOResponse?
    do {
      response = try rh.handleRequest(request)
    }
    catch {
      log.error("Failed to generate response:", error)
      let r = WOResponse(request: request)
      r.status = 500
      try? r.appendContentHTMLString("Error during response generation.")
      response = r
    }
    
    if response == nil && request.uri == "/favicon.ico", let data = favicon {
      let r = WOResponse(request: request)
      r.setHeader("image/x-icon", for: "Content-Type")
      r.contents = data
      response = r
    }

    guard let finalResponse = response else {
      // e.g. favicon.ico
      log.trace("Got no response to request:", request)
      let r = WOResponse(request: request)
      r.status = 500
      try? r.appendContentHTMLString("Could not generate response.")
      return r
    }
    
    // TODO: add CORS headers
    
    return finalResponse
  }
  
  open func createContext(for request: WORequest) -> WOContext {
    return (contextClass ?? WOAppContext.self)
           .init(application: self, request: request)
  }
  

  // MARK: - Request Handlers
  
  var requestHandlerRegistry = [ String : WORequestHandler ]()
  
  /**
   * Returns the WORequestHandler which is responsible for the given request.
   * This retrieves the request handler key from the request. If there is none,
   * or if the key maps to nothing the `defaultRequestHandler()` is
   * used.
   * Otherwise the WORequestHandler stored for the key will be returned.
   *
   * @param _rq - the WORequest to be handled
   * @return a WORequestHandler object responsible for processing the request
   */
  open func requestHandler(for request: WORequest) -> WORequestHandler? {
    if request.uri == "/favicon.ico" {
      if let rh = requestHandlerRegistry[resourceRequestHandlerKey] {
        return rh
      }
    }
    
    guard let key = request.requestHandlerKey,
          let rh = requestHandlerRegistry[key] else
    {
      return defaultRequestHandler
    }
    
    return rh
  }
  
  open func registerRequestHandler(_ rh: WORequestHandler, for key: String) {
    requestHandlerRegistry[key] = rh
  }
  open var registeredRequestHandlerKeys : [ String ] {
    return Array(requestHandlerRegistry.keys)
  }
  
  open var defaultRequestHandler : WORequestHandler?
  
  open var directActionRequestHandlerKey : String {
    return properties.string(forKey: "WODirectActionRequestHandlerKey") ?? "wa"
  }
  open var componentRequestHandlerKey : String {
    return properties.string(forKey: "WOComponentRequestHandlerKey") ?? "wo"
  }
  open var resourceRequestHandlerKey : String {
    return properties.string(forKey: "WOResourceRequestHandlerKey") ?? "wr"
  }

  
  // MARK: - Errors
  
  open func handleError(_ error: Swift.Error, in context: WOContext)
            -> WOActionResults?
  {
    // TODO: special thing for GoSecurityException
    do {
      return try renderObject(error, in: context)
    }
    catch {
      log.error("Error while rendering error:", error)
      return nil
    }
  }
  
  open func handleSessionRestorationError(in context: WOContext)
            -> WOActionResults?
  {
    let r = context.application.redirectToApplicationEntry(in: context)
    let u = r?.header(for: "Location") ?? ("/" + context.application.name)
    
    let myResponse = WOResponse(request: context.request)
    try? myResponse.appendContentString(
      """
      <h2>Could not restore session!</h2>
      <p>
        Return to application entry point:
        <a href="\(u)">\(context.application.name.htmlEscaped)</a>
      </p>
      """
    )
    return myResponse
  }
  
  open func handlePageRestorationError(in context: WOContext)
            -> WOResponse
  {
    // long time, no see :-)
    context.response.status = 500 // TBD
    try? context.response
                .appendContentString("<h1>You have backtracked too far</h1>!")
    return context.response
  }
  
  open func handleMissingAction(_ action: String, in context: WOContext)
            -> WOActionResults?
  {
    try? context.response.appendContentHTMLString("Missing action: \(action)!")
    return context.response
  }
  
  
  // MARK: - Rendering Results
  
  /**
   * This methods determines the renderer for the given object in the given
   * context.
   *
   * - if the object is null, we return null
   * - if the object is a GoSecurityException, we check whether the
   *     authenticator of the exceptions acts as a IGoObjectRendererFactory.
   *     If this returns a result, it is used as the renderer.
   * - next, if there is a context the
   *     IGoObjectRendererFactory.Utility.rendererForObjectInContext()
   *     function is called in an attempt to locate a renderer by traversing
   *     the path, looking for a IGoObjectRendererFactory which can return
   *     a result.
   * - then, the products are checked for appropriate renderers, by
   *     invoking the rendererForObjectInContext() of the product manager.
   * - and finally the GoDefaultRenderer will get used (if it can process
   *     the object)
   *
   * @param _o   - the object which shall be rendered
   * @param _ctx - the context in which the rendering should happen
   * @return a renderer object (a GoObjectRenderer)
   */
  open func rendererForObject(_ object: Any?, in context: WOContext)
            -> GoObjectRenderer?
  {
    // TODO: the security stuff
    // TODO: Go traversal path lookup
    // TODO: product support
    
    if GoDefaultRenderer.shared.canRenderObject(object, in: context) {
      return GoDefaultRenderer.shared
    }
    
    return nil
  }
  
  /**
   * Renders the given object in the given context. It does so by looking up
   * a 'renderer' object (a GoObjectRenderer) using
   * rendererForObjectInContext() and then calling renderObjectInContext()
   * on it.
   *
   * In the default configuration this will usually use the GoDefaultRenderer
   * which can deal with quite a few setups.
   *
   * @param _result - the object to be rendered
   * @param _ctx    - the context in which the rendering should happen
   * @return a WOResponse containing the rendered results
   */
  open func renderObject(_ object: Any?,
                         in context: WOContext) throws -> WOResponse?
  {
    guard let renderer = rendererForObject(object, in: context) else {
      log.error("did not find renderer for object:", object,
                "type:", type(of: object))
      let r = context.response
      r.status = 500
      try? r.appendContentHTMLString("did not find renderer for object")
      return r
    }
    
    do {
      try renderer.renderObject(object, in: context)
    }
    catch {
      do {
        return try renderObject(error, in: context)
      }
      catch {
        return nil
      }
    }
    return context.response
  }
  
  /**
   * This method is called by the GoDefaultRenderer if its asked to render a
   * WOApplication object. This usually means that the root-URL of the
   * application was accessed.
   * The default implementation will return a redirect to the `wa/Main/default`
   * GoPath.
   *
   * @param _ctx - the WOContext the request happened in
   * @return a WOResponse to be used for the application object
   */
  open func redirectToApplicationEntry(in context: WOContext) -> WOResponse? {
    let drh = defaultRequestHandler
    let rm  = resourceManager
    
    let url : String
    if drh is WODirectActionRequestHandler, let rm = rm,
       rm.lookupDirectActionClass("DirectAction") != nil
    {
      url = "DirectAction/default"
    }
    else if let rm = rm, rm.lookupComponentClass("Main") != nil {
      url = "Main/default"
    }
    else {
      log.error("Did not find DirectAction or Main for initial request")
      return nil
    }
    
    var qd = [ String : Any? ]()
    for ( name, values ) in context.request.formValues {
      qd[name] = values
    }
    if context.hasSession {
      qd[WORequest.SessionIDKey] = context.session.sessionID
    }
    else {
      qd.removeValue(forKey: WORequest.SessionIDKey)
    }
    
    let fullURL = context.directActionURLForActionNamed(url, with: qd)
    
    let response = WOResponse(request: context.request)
    response.status = 302 // Found
    response.setHeader(fullURL, for: "Location")
    return response
  }
  
  
  // MARK: - Responder
  
  /**
   * This starts the takeValues phase of the request processing. In this phase
   * the relevant objects fill themselves with the state of the request before
   * the action is invoked.
   *
   * The default method calls the takeValuesFromRequest() of the WOSession, if
   * one is active. Otherwise it enters the contexts' page and calls
   * takeValuesFromRequest() on it.
   */
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    if context.hasSession {
      try context.session.takeValues(from: request, in: context)
    }
    else if let page = context.page {
      context.enterComponent(page)
      defer { context.leaveComponent(page) }
      try page.takeValues(from: request, in: context)
    }
  }
  
  /**
   * This triggers the invokeAction phase of the request processing. In this
   * phase the relevant objects got their form values pushed in and the action
   * is ready to be performed.
   *
   * The default method calls the invokeAction() of the WOSession, if
   * one is active. Otherwise it enters the contexts' page and calls
   * invokeAction() on it.
   */
  open func invokeAction(for request : WORequest,
                         in  context : WOContext) throws -> Any?
  {
    if context.hasSession {
      return try context.session.invokeAction(for: request, in: context)
    }
    else if let page = context.page {
      context.enterComponent(page)
      defer { context.leaveComponent(page) }
      return try page.invokeAction(for: request, in: context)
    }
    else {
      return nil
    }
  }
  
  /**
   * Render the page stored in the WOContext. This works by calling
   * appendToResponse() on the WOSession, if there is one. If there is none,
   * the page set in the context will get invoked directly.
   *
   * @param _response - the response
   * @param _ctx      - the context
   */
  open func append(to response: WOResponse, in context: WOContext) throws {
    if context.hasSession {
      try context.session.append(to: response, in: context)
    }
    else if let page = context.page {
      context.enterComponent(page)
      defer { context.leaveComponent(page) }
      try page.append(to: response, in: context)
    }
  }
  
  
  // MARK: - Sessions
  
  /**
   * Sets the session store of the application.
   *
   * *Important!*: Only call this method in properly locked sections, the
   * sessionStore ivar is not protected.
   *
   * Usually you should only call this in the applications init() method or
   * constructor.
   */
  open var sessionStore : WOSessionStore
  
  /**
   * Uses the configured WOSessionStore to unarchive a WOSession for the current
   * request(/context).
   * All code should use this method instead of directly dealing with the
   * session store.
   *
   * Note: this method also checks out the session from the store to avoid
   *       concurrent modifications!
   */
  open func restoreSession(with id: String, in ctx: WOContext) -> WOSession? {
    let session = sessionStore.checkOutSession(for: id, from: ctx.request)
    
    // TODO: scan cookies, port (if session == nil)
    
    if let session = session {
      ctx.session = session
      session.awake(in: ctx)
    }
    
    return session
  }
  
  /**
   * Save the session to a store and check it in.
   */
  open func saveSession(of context: WOContext) -> Bool {
    guard context.hasSession else { return false }
    
    context.session.sleep(in: context)
    sessionStore.checkInSession(of: context)
    return true
  }
  
  /**
   * Can be overridden by subclasses to configure whether an application should
   * refuse to accept new session (eg when its in shutdown mode).
   * The method always returns false in the default implementation.
   */
  open var refusesNewSessions : Bool { return false }
  
  open var defaultSessionTimeOut : TimeInterval {
    let t = UserDefaults.standard.integer(forKey: "WOSessionTimeOut")
    return TimeInterval(t > 0 ? t : 3600)
  }
  
  /**
   * This is called by WORequest or our handleRequest() in case a session needs
   * to be created. It calls createSessionForRequest() to instantiate the clean
   * session object. It then registers the session in the context and performs
   * wake up (calls awakeWithContext()).
   *
   * @param _ctx the context in which the session shall be active initially.
   * @return a fresh session
   */
  open func initializeSession(in context: WOContext) -> WOSession? {
    guard let session = createSession(for: context.request) else { return nil }
    session.timeout = defaultSessionTimeOut
    context.setNewSession(session)
    session.awake(in: context)
    return session
  }
  
  /**
   * Called by initializeSession to create a new session for the given request.
   *
   * This method is a hook for subclasses which want to change the class of
   * the WOSession object based on the request. If they just want to change the
   * static class, they can change the 'sessionClass' ivar.
   *
   * @param _rq  the request which is associated with the new session.
   * @return a new, not-yet-awake session
   */
  open func createSession(for request: WORequest) -> WOSession? {
    return (sessionClass ?? WOSession.self).init()
  }
  
  // TBD: I think this configures how 'expires' is set
  open var isPageRefreshOnBacktrackEnabled : Bool = true
  
  
  /**
   * This method gets called by WOContext if its asked to restore a query
   * session. If you want to store complex objects in your session, you might
   * want to override this.
   */
  open func restoreQuerySession(in context: WOCoreContext) -> WOQuerySession {
    return WOQuerySession(context: context)
  }
  
  
  // MARK: - Page Handling
  
  /**
   * Primary method for user code to generate new WOComponent objects. This is
   * also called by WOComponent.pageWithName().
   *
   * The method first locates a WOResourceManager by asking the active
   * component, and if this has none, it uses the WOResourceManager set in the
   * application.
   * It then asks the WOResourceManager to instantiate the page. Afterwards it
   * awakes the component in the given WOContext.
   *
   * Again: do not trigger the WOResourceManager directly, always use this
   * method (or WOComponent.pageWithName()) to acquire WOComponents.
   *
   * @param _pageName - the name of the WOComponent to instantiate
   * @param _ctx      - the context for the component
   * @return the WOComponent or null if the WOResourceManager found none
   */
  open func pageWithName(_ name: String, in context: WOContext) -> WOComponent?
  {
    guard let rm = context.component?.resourceManager ?? resourceManager else {
      log.error("Did not find resource manager to instantiate page:", name)
      return nil
    }
    
    guard let page = rm.pageWithName(name, in: context) else {
      log.error("Did not instantiate page:", name, "using:", rm)
      return nil
    }
    
    page.ensureAwake(in: context)
    
    return page
  }
  
  
  // MARK: - Resource Manager
  
  open var resourceManager : WOResourceManager? = nil {
    didSet {
      guard let rm = resourceManager else { return }
      if sessionClass == nil {
        sessionClass = rm.lookupClass("Session") as? WOSession.Type
      }
      if contextClass == nil {
        contextClass = rm.lookupClass("Context") as? WOContext.Type
      }
    }
  }

  
  // MARK: - KVC
  
  lazy var typeInfo = try? Runtime.typeInfo(of: type(of: self))
  
  open func value(forKey k: String) -> Any? {
    switch k {
      case "name":                          return name
      case "resourceManager":               return resourceManager
      case "defaultRequestHandler":         return defaultRequestHandler
      case "registeredRequestHandlerKeys":  return registeredRequestHandlerKeys
      case "directActionRequestHandlerKey": return directActionRequestHandlerKey
      case "componentRequestHandlerKey":    return componentRequestHandlerKey
      case "resourceRequestHandlerKey":     return resourceRequestHandlerKey
      case "sessionStore":                  return sessionStore
      case "refusesNewSessions":            return refusesNewSessions
      case "defaultSessionTimeOut":         return defaultSessionTimeOut
      case "isPageRefreshOnBacktrackEnabled":
        return isPageRefreshOnBacktrackEnabled
      default: break
    }
    
    guard let ti = typeInfo, let prop = try? ti.property(named: k) else {
      return handleQueryWithUnboundKey(k)
    }
    guard let v = try? prop.get(from: self) else {
      log.error("Failed to get KVC property:", k)
      return nil
    }
    
    return v
  }
}

public protocol WORequestDispatcher {
  // This is a main reason why the WO API would need to be adjusted for modern,
  // async, processing. But then, people are still using RoR! ;-)
  
  func dispatchRequest(_ request: WORequest) -> WOResponse
  
}

public protocol WOLifecycle {
  
  func awake()
  func sleep()
  
}

