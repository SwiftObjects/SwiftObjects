//
//  WOContext.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Runtime

/**
 * The WOContext is the context for one HTTP transaction, that is, one
 * request/response cycle. It provides access to all objects required for
 * handling the requests, this includes request, response, the session,
 * the current page and so on.
 *
 * THREAD: WOContext is not threadsafe, its supposed to be used from one thread
 *         only (the one processing the HTTP request).
 */
public protocol WOContext : WOCoreContext, WOLifecycle,
                            KeyValueCodingType, MutableKeyValueCodingType
{
  
  init(application: WOApplication, request: WORequest)

  var session             : WOSession  { get set }
  var hasNewSession       : Bool       { get }
  var languages           : [ String ] { get }
  var savePageRequired    : Bool       { get set } // set is kinda internal
  var isRenderingDisabled : Bool       { get }
  var fragmentID          : String?    { get set }
  
  @discardableResult func disableRendering() -> Bool
  @discardableResult func enableRendering() -> Bool

  var hasSession          : Bool       { get }
  
  /**
   * Returns the element-id of the currently active element. The element-id can
   * be assigned manually, or it is an automatically generated path. The id is
   * calculated by the path the elements flow and repeat through the template
   * tree.
   * Careful: this is *not* just the node positions, element ids are also
   * added/removed by elements like repetitions or conditions! (the contents of
   * a repetition need own IDs, not their index in the tree)
   *
   * Unlike SOPE the Go/So element id does NOT include the context-id.
   *
   * @return a unique identifier for the current element (in page scope)
   */
  var elementID           : String     { get set }
  
  var senderID            : String?    { get }
  
  func setRequestSenderID(_ id: String)

  func setNewSession(_ sn: WOSession)
  
  /**
   * Returns the WOQuerySession attached to the context. This calls the
   * WOApplication's restoreQuerySessionInContext() on demand to set up
   * the query session.
   */
  var querySession        : WOQuerySession   { get }

  /**
   * This method uses the query session to determine which query parameters
   * should be included in a URL. The method is called by URL generating dynamic
   * elements (eg WOHyperlink).
   */
  var allQuerySessionValues : [ String : Any ] { get }

  // TODO: languages, locale, timezone
  
  var page                : WOComponent? { get set }
  var cursor              : Any?         { get }
  var component           : WOComponent? { get }
  var parentComponent     : WOComponent? { get }
  var componentContent    : WOElement?   { get }
  
  /**
   * If a WOForm is entered, it calls this method to remember the fact. Remember
   * that forms must not be nested.
   */
  var isInForm            : Bool         { get set }
  
  /**
   * This method is called during the takeValues() phase by WOInput elements to
   * register an element as the active one. Eg if a WOSubmitButton encounters
   * that its value is set during takeValues() it will set itself as the active
   * form element (since only the values of the pressed submit button are
   * transmitted, hence can be used to detect the action).
   *
   * This basically moves the invoke step to the take values process for form
   * values. Actually this should not be strictly necessary?
   *
   * @param _element - the WOElement for the action (usually an WOInput object)
   */
  func addActiveFormElement(_ element: WOElement)
  
  /**
   * Returns the element (usually an WOInput) which registered itself as the
   * active one during the takeValues() phase.
   */
  var activeFormElement : WOElement? { get }

  /**
   * Returns the currently active WOErrorReport. This method is called by
   * dynamic elements (eg WOInput) which want to attach errors.
   * The value can be null (in this case the elements usually throw an
   * exception).
   *
   * Error reports are pushed to the WOContext using the pushErrorReport()
   * method. For example this is called by WOForm if the errorReport binding
   * is set.
   *
   * @return the active WOErrorReport object
   */
  var errorReport : WOErrorReport? { get }
  
  /**
   * This method is used to push a new WOErrorReport object to the stack of
   * error reports. New error reports will be attached to their parent report,
   * so that a hierarchy of reports can be built.
   * E.g. it is called by WOForm if the 'errorReport' binding is set.
   *
   * @param _report - the new WOErrorReport object
   */
  func pushErrorReport(_ report : WOErrorReport)
  func popErrorReport () -> WOErrorReport?

  
  /**
   * An internal method which is called from various places. It registers a
   * component as awake (it does NOT trigger the awake() method).
   */
  func _addAwakeComponent(_ component: WOComponent)
  
  func enterComponent(_ component: WOComponent, content: WOElement?)
  func leaveComponent(_ component: WOComponent)

  var rootResourceManager : WOResourceManager? { get }
}

public extension WOContext {
  
  public func enterComponent(_ component: WOComponent) {
    enterComponent(component, content: nil)
  }

  public var cursor : Any? {
    return component
  }
  
}


// MARK: - URL generation

public extension WOContext {

  public var hasErrorReport : Bool { return errorReport != nil }
  
  /**
   * Composes a URL suitable for use with the given request handler.
   *
   * Important: this does *not* add any query parameters (like wosid).
   */
  public func urlWithRequestHandlerKey(_ key: String,
                                       path: String? = nil,
                                       query: String? = nil)
              -> String
  {
    var sb = ""
    
    if let v = request.adaptorPrefix, !v.isEmpty {
      sb += v
    }
    
    let appName = request.applicationName ?? application.name
    if sb.isEmpty || !sb.hasSuffix("/") { sb += "/" }
    sb += appName
    
    sb += "/"
    sb += key
    if let v = path, !v.isEmpty {
      if !v.hasPrefix("/") { sb += "/" }
      sb += v
    }
    if let v = query, !v.isEmpty {
      sb += "?"
      sb += v
    }
    return sb
  }
  
  /**
   * Constructs a component action URL for the currently active element. This
   * URL includes the sessionID as well as the currently active elementID.
   *
   * This method calls urlWithRequestHandlerKey to perform the final assembly.
   */
  public func componentActionURL() -> String? {
    /*
     * This makes the request handler save the page in the session at the
     * end of the request (only necessary if the page generates URLs which
     * refer the context).
     */
    savePageRequired = true
    
    return urlWithRequestHandlerKey(
      application.componentRequestHandlerKey,
      path: session.sessionID + "/" + contextID + "/" + elementID
    )
  }
  
  /**
   * Generates a URL for the given direct action.
   *
   * Important: this does *not* embed a session id! Session ids or query
   * session parameters are added to the queryDict by the respective
   * WODynamicElement class (usually WOLinkGenerator).
   *
   * @param _name      - a direct action name, eg "Main/default"
   * @param _queryDict - set of query parameters to be included in the URL
   * @return a URL
   */
  public
  func directActionURLForActionNamed(_ name: String,
                                     with queryDictionary: [ String : Any? ]?)
            -> String
  {
    let qs = queryDictionary?.stringForQueryDictionary()
    return urlWithRequestHandlerKey(application.directActionRequestHandlerKey,
                                    path: name, query: qs)
  }
  
  /**
   * Generates a URL for the given direct action.
   *
   * Important: this does *not* embed a session id! Session ids or query
   * session parameters are added to the queryDict by the respective
   * WODynamicElement class (usually WOLinkGenerator).
   *
   * @param _name      - a direct action name, eg "Main/default"
   * @return a URL
   */
  public func directActionURLForActionNamed(_ name: String) -> String {
    return urlWithRequestHandlerKey(application.directActionRequestHandlerKey,
                                    path: name, query: nil)
  }

  
  /**
   * Same like directActionURLForActionNamed(name,dict), but this prepares the
   * query dictionary with the query session parameters and the session-id (if
   * one is active).
   *
   * @param _name            - name of the direct action (eg Main/default)
   * @param _queryDict       - query parameters
   * @param _addSnId         - whether to include the session id (?wosid)
   * @param _incQuerySession - whether to include the query session
   * @return a URL pointing to the direct action
   */
  public
  func directActionURLForActionNamed(_ name: String,
                                     with queryDictionary : [ String : Any? ]?,
                                     addSessionID         : Bool = false,
                                     includeQuerySession  : Bool = false)
            -> String
  {
    if !addSessionID && !includeQuerySession {
      return directActionURLForActionNamed(name, with: queryDictionary)
    }
    
    let querySession : WOQuerySession? = {
      guard includeQuerySession else { return nil }
      guard self.querySession.hasActiveQuerySessionValues else { return nil }
      return self.querySession
    }()
    
    let sessionID = addSessionID && hasSession ? (session.sessionID) : nil
    
    if querySession == nil && sessionID == nil {
      return directActionURLForActionNamed(name, with: queryDictionary)
    }
    
    var qd = queryDictionary ?? [:]
    querySession?.add(to: &qd)
    if let sessionID = sessionID {
      qd[WORequest.SessionIDKey] = sessionID
    }
    
    return directActionURLForActionNamed(name, with: qd)
  }
  
}


// MARK: - Element IDs

public extension WOContext {
  
  public func appendElementIDComponent(_ id: String) {
    if !elementID.isEmpty { elementID += "." }
    elementID += id
  }
  public func appendElementIDComponent(_ id: Int) {
    if !elementID.isEmpty { elementID += "." }
    elementID += String(id)
  }

  /**
   * Adds a zero to the element ID. Example:
   *
   *     "2.3.4.5" => "2.3.4.5.0"
   *     ""        => "0"
   *
   */
  public func appendZeroElementIDComponent() {
    if elementID.isEmpty { elementID +=  "0" }
    else                 { elementID += ".0" }
  }
  
  /**
   * Increments the last part of the element-id. Example
   *
   *     "2.3.4.5" => "2.3.4.6"
   *     "2"       => "3"
   *
   */
  public func incrementLastElementIDComponent(by value: Int = 1) {
    if let r = elementID.range(of: ".", options: .backwards) {
      let prefix = elementID[elementID.startIndex..<r.upperBound]
      let num    = elementID[r.upperBound..<elementID.endIndex]
      let v      = (Int(num) ?? 0) + value
      elementID = prefix + String(v)
    }
    else {
      let v = (Int(elementID) ?? 0) + value
      elementID = String(v)
    }
  }

  /**
   * Deletes the last part of the element-id. Example
   *
   *     "2.3.4.5" => "2.3.4"
   *     "2"       => ""
   *
   */
  public func deleteLastElementIDComponent() {
    if let r = elementID.range(of: ".", options: .backwards) {
      elementID = String(elementID[elementID.startIndex..<r.lowerBound])
    }
    else {
      elementID.removeAll()
    }
  }
  
  /**
   * Completely clears the element-id (to the empty string "").
   */
  public func deleteAllElementIDComponents() {
    elementID.removeAll()
  }
}


// MARK: - Concrete Object

open class WOAppContext : WOCoreContextBase, WOContext, ExtraVariables {
  
  open var hasNewSession        = false
  open var savePageRequired     = false
  open var isRenderingDisabled  = false
  open var fragmentID           : String? = nil
  open var elementID            = ""
  open var senderID             : String? = nil
  open var isInForm             : Bool = false
  open var activeFormElement    : WOElement? = nil
  open var errorReports         = [ WOErrorReport ]()
  
  public var variableDictionary = [ String : Any ]()
  
  var _languages      : [ String ]?
  var _session        : WOSession?
  var _querySession   : WOQuerySession?

  var awakeComponents = [ WOComponent ]()
  var componentStack  = [ WOComponent ]()
  var contentStack    = [ WOElement?  ]()
  

  override
  required public init(application: WOApplication, request: WORequest) {
    super.init(application: application, request: request)
  }
  
  
  // MARK: - Lifecycle
  
  open func awake() {
  }
  open func sleep() {
    sleepComponents()
    if hasSession { session.sleep(in: self) }
  }
  
  
  // MARK: - Languages

  open var languages : [ String ] {
    set { _languages = newValue }
    
    /**
     * Returns the List of languages associated with this request. This method is
     * checked for localization.
     *
     * @return a List of language codes (eg ['en', 'de'])
     */
    get {
      if let langs = _languages { return langs }
      if hasSession, let langs = session.languages { return langs }
      return request.browserLanguages ?? []
    }
  }

  
  // MARK: - Session
  
  open var session : WOSession {
    set {
      _session = newValue
    }
    get { // FIXME: clumsy
      if let sn = _session { return sn }
      guard let sn = application.initializeSession(in: self) else {
        _session = WOSession() // weird, fix me
        return _session!
      }
      return sn
    }
  }

  open var hasSession : Bool { return _session != nil }
  
  open func setNewSession(_ sn: WOSession) {
    session       = sn
    hasNewSession = true
  }
  
  
  // MARK: - Query Session
  
  open var querySession : WOQuerySession {
    if let qs = _querySession { return qs }
    let qs = application.restoreQuerySession(in: self)
    _querySession = qs
    return _querySession!
  }
  
  open var allQuerySessionValues : [ String : Any ] {
    return querySession.allQuerySessionValues
  }
  
  open func setRequestSenderID(_ id: String) {
    senderID = id
  }

  
  // MARK: - Components

  open var page : WOComponent? {
    didSet { page?.ensureAwake(in: self) }
  }
  
  open var componentContent : WOElement? {
    guard let last = contentStack.last else { return nil }
    return last
  }
  open var component : WOComponent? {
    return componentStack.last ?? page
  }
  open var parentComponent : WOComponent? {
    guard componentStack.count > 1 else { return nil }
    let idx = componentStack.index(componentStack.endIndex, offsetBy: -2)
    return componentStack[idx]
  }
  
  open func enterComponent(_ component: WOComponent, content: WOElement?) {
    componentStack.append(component)
    contentStack  .append(content)
    
    _awakeComponent(component)
    
    if componentStack.count > 1 {
      component.pullValuesFromParent()
    }
  }
  
  open func leaveComponent(_ component: WOComponent) {
    guard component === self.component else {
      // TODO: scan stack for _component to see whether the _component is
      //       upcoming, do something useful
      return
    }
    
    if componentStack.count > 1 {
      component.pushValuesToParent()
    }
    
    componentStack.removeLast()
    contentStack  .removeLast()
  }

  open func _addAwakeComponent(_ component: WOComponent) {
    awakeComponents.append(component)
  }
  open func _awakeComponent(_ component: WOComponent) {
    guard !awakeComponents.contains(where: { $0 === component }) else { return }
    component._awakeWithContext(self)
    _addAwakeComponent(component)
  }
  
  /**
   * Calls the sleep() method on all components which got an awake() call with
   * this context.
   * This is called in WOApp.handleRequest() before a session is saved to ensure
   * that just the necessary state is preserved.
   */
  open func sleepComponents() {
    var sendSleepToPage = true
    
    for component in awakeComponents {
      component._sleepWithContext(self)
      if component === page { sendSleepToPage = false }
    }
    awakeComponents.removeAll()
    
    if sendSleepToPage, let page = page {
      page._sleepWithContext(self)
    }
  }
  
  
  // MARK: - Forms

  open func addActiveFormElement(_ element: WOElement) {
    guard activeFormElement == nil else {
      log.error("active form element already set:", element, self);
      return
    }
    
    activeFormElement = element
    
    // TBD: is this really necessary? The element-id has no relevance?
    setRequestSenderID(elementID)
  }

  open var errorReport : WOErrorReport? { return errorReports.last }
  
  open func pushErrorReport(_ report : WOErrorReport) {
    errorReports.append(report)
  }
  open func popErrorReport() -> WOErrorReport? {
    return errorReports.popLast()
  }

  
  // MARK: - Resource Manager

  open var rootResourceManager : WOResourceManager? {
    return application.resourceManager
  }
  
  
  // MARK: - Rendering

  @discardableResult
  open func disableRendering() -> Bool {
    let old = isRenderingDisabled
    isRenderingDisabled = true
    return old
  }
  @discardableResult
  open func enableRendering() -> Bool {
    let old = isRenderingDisabled
    isRenderingDisabled = false
    return old
  }


  // MARK: - KVC
  
  lazy var typeInfo = try? Runtime.typeInfo(of: type(of: self))
  
  open func takeValue(_ value : Any?, forKey k: String) throws {
    if variableDictionary[k] != nil {
      if let value = value { variableDictionary[k] = value }
      else { variableDictionary.removeValue(forKey: k) }
    }
    
    switch k {
      case "elementID", "senderID", "savePageRequired", "isRenderingDisabled",
           "variableDictionary",
           "isInForm",
           "session", "hasSession", "hasNewSession", "querySession",
           "errorReports", "hasErrorReport", "errorReport",
           "awakeComponents", "componentStack", "contentStack",
           "allQuerySessionValues", "componentActionURL",
           "page", "cursor", "component", "parentComponent",
           "rootResourceManager":
        return try handleTakeValue(value, forUnboundKey: k)
      
      case "fragmentID":
        fragmentID = value as? String
        return
      
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
      case "application":           return application
      case "elementID":             return elementID
      case "senderID":              return senderID
      case "savePageRequired":      return savePageRequired
      case "isRenderingDisabled":   return isRenderingDisabled
      case "fragmentID":            return fragmentID
      case "session":               return session
      case "hasSession":            return hasSession
      case "hasNewSession":         return hasNewSession
      case "querySession":          return querySession
      case "errorReports":          return errorReports
      case "languages":             return languages
      case "allQuerySessionValues": return allQuerySessionValues
      case "page":                  return page
      case "cursor":                return cursor
      case "component":             return component
      case "parentComponent":       return parentComponent
      case "rootResourceManager":   return rootResourceManager
      case "componentActionURL":    return componentActionURL
      case "hasErrorReport":        return hasErrorReport
      case "errorReport":           return errorReport
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
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if !elementID.isEmpty   { ms += " eid=\(elementID)" }
    if let sid = senderID   { ms += " sender=\(sid)"    }
    if let fid = fragmentID { ms += " fragment=\(fid)"  }

    if savePageRequired     { ms += " needs-save" }
    if isRenderingDisabled  { ms += " render-off" }
    if isInForm             { ms += " in-form"    }
    
    if let sn = _session      { ms += " sid=\(sn.sessionID)" }
    if let qs = _querySession { ms += " qs=\(qs)" }
    
    if let _ = activeFormElement {
      ms += " has-active-form-element"
    }
    
    if !variableDictionary.isEmpty {
      ms += " #vars=\(variableDictionary.keys)"
    }
    
    if let l = _languages, !l.isEmpty {
      ms += " langs="
      ms += l.joined(separator: ",")
    }
    
    if !errorReports.isEmpty {
      ms += " errors=\(errorReports)"
    }
    
    if awakeComponents.count > 1 { ms += " #awake=\(awakeComponents.count)" }
    if componentStack.count  > 1 { ms += " #stack=\(componentStack.count)"  }
    if contentStack.count    > 1 { ms += " #content=\(contentStack.count)"  }
  }
}
