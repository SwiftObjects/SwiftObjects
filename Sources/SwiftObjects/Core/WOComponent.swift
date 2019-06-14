//
//  WOComponent.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Runtime

/**
 * Subclasses of WOComponent are used to represent template based pages or
 * reusable components in Go. A component (usually) is a Swift subclass of
 * WOComponent plus a template. The exact format of the template depends on the
 * respective template builder, usually the WOWrapperTemplateBuilder is used.
 *
 * ### WOComponent vs WODynamicElement
 *
 * Both, WOComponent and WODynamicElement, inherit from the WOElement
 * superclass. The major conceptual difference is that WOComponent's have own
 * per-transaction or per-session state while WODynamicElement's have *no* own
 * instance variable state but retrieve state using WOAssociations from the
 * active component.
 *
 * Plus WODynamicElements almost always directly render HTML/XML/xyz in Swift
 * code while WOComponent's usually have an associated template. (both are not
 * exact requirements, a WOComponent can also directly render w/o a template and
 * a WODynamicElement could load a stateless sub-template).
 *
 * ### Subcomponents
 *
 * FIXME: Explain better how subcomponents work.
 *
 * Components can refer other components in the template, like:
 *
 *     <#ZideBox title="Hello" />
 *
 * This does two things: the template will get an WOChildComponentReference
 * dynamic element which represents the component in the template hierarchy,
 * AND upon instantiation the component will get an entry in its 'subcomponents'
 * Map. Usually the subcomponent will start out as a WOComponentFault. Only
 * if it is actually needed, a real WOComponent instance will be created.
 *
 * Note: There are two hierarchies alongside each other: the stateless
 * template hierarchy of WODynamicElements and the stateful component hierarchy.
 *
 * Parameters like the 'title' in the example are synchronized when the control
 * between the components goes back and forth (the values are pushed in and out
 * via KVC).
 *
 * ### Stateless Components
 *
 * FIXME: Don't quite remember how those work. (hh 2014)
 * I think the idea is that a stateless component is like a WODynamicElement,
 * with the difference, that you can use pageWithName and such to look them up
 * and have a template associated with it.
 *
 * ### Relationship to WOContext
 *
 * Unless it is a stateless component a component is always associated with a
 * WOContext. The WOContext tracks which components are awake and such, and it
 * tracks the current component activation chain (consider it the callstack
 * of the components).
 *
 * ### Differences to WebObjects
 *
 * #### Initialization
 *
 * Apparently the initialization is a bit different? Something about
 * default-constructor and initWithContext.<br>
 * FIXME: check what exactly.
 *
 * #### Go WOComponent's can be used as WODirectAction's
 *
 * In Go components can be directly used as direct actions. In traditional WO
 * one usually has a direct action, which then instantiates a WOComponent,
 * passes over rendering arguments and then returns it for rendering.
 *
 * This can be reduced in Go. In Go you can directly invoke a component like
 * a direct action, sample:
 *
 *   class Main extends WOComponent {
 *     ...
 *     public WOActionResults showAction() { ...
 *
 *   Invoke via:
 *     /MyApp/wa/Main/show?id=5
 *
 * All the rules of WODirectAction apply. Actions must be suffixed 'Action'
 * and if none is specified, defaultAction is invoked.
 *
 * #### Component specific WOResourceManager's
 *
 * In Go there is the concept of component-specific WOResourceManager's. WO
 * only has a global one (Go falls back to this if there is no local one).
 *
 * This is to support OFS and other hierarchical Go publishing setups. Example:
 *
 *     /MyApp/persons/person/index.wo
 *     /MyApp/persons/index.wo
 *     /MyApp/Frame.wo
 *
 * With the right resource manager the components can perform lookup of
 * resources relative to the position of the source component.
 *
 * #### Redirect and F()
 *
 * Go has the convenience redirectToLocation() method.
 * To retrieve form values one can use the F() methods, sample:
 *
 *     /MyApp/wa/Persons/fetch?limit=50
 *     int fetchLimit = UObject.intValue(F("limit", 10));
 *
 * ### Integration with the Zope-like Go publishing system
 *
 * FIXME: document more.
 *
 * A WOComponent is an IGoObject, an IGoObjectRenderer and an
 * IGoObjectRendererFactory.
 *
 * FIXME: write about GoPageInvocation and how a WOComponent usually is not
 * directly part of the traversal path.
 *
 * The IGoObject implementation supports lookup of direct action methods (as
 * Go methods). Plus lookup using the Go class.
 * Sample: 'lookupName("show");' will give you a GoCallable 'showAction'.
 *
 * Careful: If you invoke a page like this:
 *
 *     /MyApp/wa/Main/show?id=5
 *
 * the Go method is 'wa', the WODirectActionRequestHandler.
 * This is why permissions on the WOComponent's are not checked here, the
 * component is not part of the Go lookup.
 */
open class WOComponent : WOElement, WOActionResults, WOLifecycle,
                         GoObjectRenderer, GoObjectRendererFactory,
                         ExtraVariables, WOActionMapper,
                         KeyValueCodingType, MutableKeyValueCodingType,
                         SmartDescription
{
  
  open   var log : WOLogger = WOPrintLogger.shared
  
  public var variableDictionary = [ String : Any ]()
  public var exposedActions     = [ String : WOActionCallback ]()

  var _wcName : String?
  
  /**
   * Returns the WOContext the component was created in. The WOContext provides
   * access to the request and response objects, to the session, and so on.
   */
  public internal(set) weak var context : WOContext?
  
  public internal(set) weak var _session : WOSession?
  
  var subcomponents = [ String : WOComponent   ]()
  var wocBindings   = [ String : WOAssociation ]()
  weak var parentComponent : WOComponent?

  /**
   * Subclasses should not use the WOComponent constructor to initialize object
   * state but rather use the initWithContext() method (do not forget to call
   * super in this).
   *
   * Note that the constructor takes no arguments, hence the context or session
   * ivars are not setup yet! This was done to reduce the code required to
   * write a WOComponent subclass (you do not need to provide a constructor).
   */
  required public init() {
  }
  deinit {
    if isAwake {
      assert(!isAwake, "component still awake in deinit (no sleep called?)")
    }
  }
  
  /**
   * Initialize the component in the given context. Subclasses should override
   * this instead of the constructor to perform per object initialization.
   *
   * @param _ctx - the WOContext
   * @return the component this was invoked on, or optionally a replacement
   */
  open func initWithContext(_ ctx: WOContext) -> WOComponent? {
    self.context = ctx
    self.log     = ctx.application.log
    return self
  }
  
  public var application : WOApplication? {
    return context?.application
  }
  
  open var name : String {
    return _wcName ?? UObject.getSimpleName(self)
  }
  
  
  // MARK: - Form Values
  
  /**
   * Dirty convenience hack to return the value of a form parameter.
   * Sample:
   *
   *     int fetchLimit = UObject.intValue(F("limit"));
   *
   * @param _fieldName - name of a form field or query parameter
   * @return Object value of the field or null if it was not found
   */
  open func F(_ name: String, default: Any? = nil) -> Any? {
    return context?.request.formValue(for: name) ?? `default`
  }
  
  
  // MARK: - Livecycle
  
  open var isStateless = false
  var isAwake = false
  
  /**
   * This method is called once per instance and context before the component
   * is being used. It can be used to perform 'late' initialization.
   */
  open func awake() {
    expose(defaultAction, as: "default")
  }
  
  open func reset() {
  }
  
  /**
   * This is called when the component is put into sleep.
   */
  open func sleep() {
    if isStateless { reset() }
    
    // may not be necessary:
    isAwake = false
    if let context = context {
      if !context.savePageRequired {
        self.context = nil
      }
    }
    _session = nil
    
    exposedActions.removeAll()
  }
  

  /**
   * Internal method to ensure that the WOComponent received its awake() message
   * and that the internal state of the component is properly setup.
   * This is called by other parts of the framework before the component is
   * used.
   *
   * @param _ctx - the WOContext
   */
  public func ensureAwake(in context: WOContext) {
    // This is now public, so that external code can implement WORequestHandlers
    
    if isAwake && self.context === context { return } // awake already
    
    if self.context == nil { self.context = context }
    if _session == nil && context.hasSession {
      _session = context.session
    }
    
    isAwake = true
    context._addAwakeComponent(self)
    
    for ( _, subcomponent ) in subcomponents {
      subcomponent._awakeWithContext(context)
    }
    
    awake()
  }
  
  /**
   * Internal method to ensure that the component is awake. The actual
   * implementation calls ensureAwakeInContext().
   *
   * Eg this is called by ensureAwakeInContext() to awake the subcomponents of
   * a component.
   *
   * @param _ctx - the WOContext to awake in
   */
  func _awakeWithContext(_ context: WOContext) {
    // TBD: we do we have _awakeWithContext() and ensureAwakeInContext()?
    /* this is called by the framework to awake the component */
    if !isAwake { // hm, flag useful/necessary? Tracked in context?
      ensureAwake(in: context)
    }
  }
  
  func _sleepWithContext(_ context: WOContext) {
    exposedActions.removeAll()
    
    guard context === self.context || self.context == nil else {
      // mismatch, awake in different context?!
      assert(context === self.context)
      return
    }
    
    if isAwake {
      isAwake = false
      
      for ( _, component ) in subcomponents {
        component._sleepWithContext(context)
      }
      
      sleep()
    }
    
    if let context = self.context {
      if !context.savePageRequired {
        self.context = nil
      }
    }
    _session = nil
  }
  
  
  // MARK: - Page Handling

  /**
   * Looks up and instantiates a new component with the given name. The default
   * implementation just forwards the call to the WOApplication object.
   */
  open func pageWithName(_ name: String) -> WOComponent? {
    guard let app = application else {
      log.error("component has no application, cannot lookup:", name, self)
      return nil
    }
    guard let context = context else {
      log.error("component has no context, cannot lookup:", name, self)
      return nil
    }
    return app.pageWithName(name, in: context)
  }
  
  
  // MARK: - WOActionResults
  
  /**
   * This method implements the WOActionResults protocol for WOComponent. It
   * creates a new WOResponse and calls appendToResponse on that response.
   *
   * @return a WOResponse containing the rendering of the WOComponent
   */
  open func generateResponse() throws -> WOResponse {
    // TBD: better create a new context?
    guard let context = self.context else {
      return WOResponse() // TODO
    }
    
    context.page = self
    ensureAwake(in: context)
    context.enterComponent(self)
    defer { context.leaveComponent(self) }
    
    let response = WOResponse(request: context.request)
    try append(to: response, in: context)
    return response
  }
  
  
  // MARK: - WODirectAction
  
  open func performActionNamed(_ name: String) throws -> Any? {
    guard let context = context else {
      log.error("component invoked as direct-action has no context assigned:",
                self)
      throw WOComponentError.componentInvokedAsDirectActionMissesContext(name)
    }
    return try WODirectAction.performActionNamed(name, on: self, in: context)
  }
  
  open func defaultAction() -> WOComponent? {
    return self
  }
  
  enum WOComponentError : Swift.Error {
    case componentInvokedAsDirectActionMissesContext(String)
  }
  
  
  // MARK: - Responder
  
  open func shouldTakeValues(from request: WORequest, in context: WOContext)
            -> Bool
  {
    return request.method == "POST" || request.hasFormValues
  }
  
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    assert(isAwake, "component not awake?")
    try template?.takeValues(from: request, in: context)
  }
  
  open func invokeAction(for request : WORequest,
                         in  context : WOContext) throws -> Any?
  {
    assert(isAwake, "component not awake?")
    let result = try template?.invokeAction(for: request, in: context)
    return result
  }

  open func append(to response: WOResponse, in context: WOContext) throws {
    assert(isAwake, "component not awake?")
    try template?.append(to: response, in: context)
    if isStateless { reset() }
  }
  
  open func walkTemplate(using walker : WOElementWalker,
                         in   context : WOContext) throws
  {
    assert(isAwake, "component not awake?")
    if let template = template {
      _ = try walker(self, template, context)
    }
    if isStateless { reset() }
  }

  
  // MARK: - Component Synchronization
  
  /**
   * This method returns whether bindings are automatically synchronized between
   * parent and child components. Per default this returns true, but
   * subcomponents can decide to return false and grab their bindings manually.
   *
   * Example:
   *
   *     Child: MyChildComponent {
   *       name = title;
   *     }
   *
   * The 'title' value of the component will be copied into the 'name' value of
   * the child if the child is entered. And its copied back when the child is
   * left.
   *
   * Note: the child needs to override synchronizesVariablesWithBindings() to
   * change the behaviour.
   */
  open var synchronizesVariablesWithBindings : Bool {
    return true // TBD: check a 'manual bind' annotation
  }

  /**
   * Internal method to pull the bound parent values into the child component.
   *
   * The component calls syncFromParent() with the parentComponent if
   * synchronizesVariablesWithBindings() returns true.
   */
  func pullValuesFromParent() { /* official WO method */
    guard synchronizesVariablesWithBindings else { return }
    
    if let parent = context?.parentComponent {
      sync(from: parent)
    }
  }
  
  /**
   * Internal method to push the bound child values into the parent component.
   *
   * The component calls syncToParent() with the parentComponent if
   * synchronizesVariablesWithBindings() returns true.
   */
  func pushValuesToParent() { /* official WO method */
    guard synchronizesVariablesWithBindings else { return }
    if let parent = context?.parentComponent {
      sync(to: parent)
    }
  }

  /**
   * This method performs the actual binding synchronization. Its usually
   * not called directly but using pullValuesFromParent().
   *
   * @param _parent - the parent component to copy values from
   */
  func sync(from parent: WOComponent) { /* SOPE method */
    for ( bindingName, binding ) in wocBindings {
      // TODO: this is somewhat inefficient because -valueInComponent: does
      //       value=>object coercion and then takeValue:forKey: does the
      //       reverse coercion. We could improve performance for base values
      //       if we implement takeValue:forKey: on our own and just pass over
      //       the raw value (ie [self setIntA:[assoc intValueComponent:self]])
      let value = binding.value(in: parent)
      try? takeValue(value, forKey: bindingName)
    }
  }
  
  /**
   * This method performs the actual binding synchronization. Its usually
   * not called directly but using pushValuesToParent().
   *
   * @param _parent - the parent component to copy values to
   */
  func sync(to parent: WOComponent) { /* SOPE method */
    let lvalues = values(forKeys: Array(wocBindings.keys))
    
    for ( bindingName, binding ) in wocBindings {
      guard binding.isValueSettableInComponent(parent) else { continue }
      try? binding.setValue(lvalues[bindingName], in: parent)
    }
  }
  
  open func hasBinding(_ name: String) -> Bool {
    return wocBindings[name] != nil
  }
  
  open func canGetValueForBinding(_ name: String) -> Bool {
    guard let a = wocBindings[name] else { return false }
    return a.isValueSettableInComponent(parentComponent)
  }
  
  open var bindingKeys : [ String ] {
    return Array(wocBindings.keys)
  }
  
  /**
   * This invokes a bound method in the context of the parent component. Calling
   * this will sync back to the parent, invoke the method and then sync down to
   * the child.
   *
   * @param _name - name of the bound parent method
   * @return the result of the called method
   */
  open func performParentAction(_ name: String) -> Any? {
    let ctx = context
    ctx?.leaveComponent(self)
    let result = KeyValueCoding.value(forKey: name, inObject: parentComponent)
    ctx?.enterComponent(self)
    return result
  }
  
  open func childComponent(with name: String) -> WOComponent? {
    guard let child = subcomponents[name] else {
      log.warn("did not find child component:", name)
      return nil
    }
    
    if let fault = child as? WOComponentFault {
      if let newChild = fault.resolve(with: self) {
        subcomponents[name] = newChild
        return newChild
      }
    }
    
    return child
  }
  
  
  // MARK: - Session Handling
  
  /**
   * Checks whether the component or the context associated with the component
   * has an active WOSession.
   *
   * @return true if a session is active, false otherwise
   */
  open var hasSession : Bool {
    if _session != nil { return true }
    return context?.hasSession ?? false
  }
  
  /**
   * Returns the session associated with the component. This checks the context
   * if no session was associated yet, and the context autocreates a new session
   * if there was none.
   *
   * If you do not want to autocreate a session, either check using `hasSession`
   * whether a session already exists or call `existingSession`
   *
   * @return an old or new WOSession
   */
  open var session : WOSession? {
    if let sn = _session { return sn }
    return context?.session // creates one on demand!
  }
  
  open var existingSession : WOSession? {
    return hasSession ? session : nil
  }
  
  
  // MARK: - Validation
  
  open func validationFailed(with error: Swift.Error,
                             value: Any? = nil,
                             keyPath: String? = nil)
  {
    // can be used in subclasses
  }
  

  // MARK: - Resource Manager
  
  var _resourceManager : WOResourceManager? = nil
  
  open var resourceManager : WOResourceManager? {
    /**
     * This assigns a specific resource manager to the component. This manager
     * is used to lookup subcomponents or other kinds of resources, like images
     * or translations.
     *
     * Usually you do NOT have a specific resource manager but use the global
     * WOApplication manager for all components.
     */
    set { _resourceManager = newValue }
    
    /**
     * Returns the resourcemanager assigned to this component. If there is no
     * specific RM assigned, it returns the global RM of the WOApplication object.
     */
    get { return _resourceManager ?? application?.resourceManager }
  }


  // MARK: - Templates

  /* templates */

  var _template : WOElement? = nil

  open var template : WOElement? {
    /**
     * Sets a WOTemplate to be used with this component. Usually we don't assign
     * a specific template to a component, but rather retrieve it dynamically
     * from the WOResourceManager.
     */
    set { _template = newValue }
    /**
     * Returns the WOElement which is being used for the component. If no
     * specific one is assigned using `template.set`, this will invoke
     * `templateWithName()` with the name of the component.
     *
     * @return a WOElement to be used as the template
     */
    get {
      if let t = _template { return t }
      // TODO: somehow this fails if the component was not instantiated using
      //       pageWithName()
      return templateWithName(name)
    }
  }
  
  /**
   * This returns the WOElement to be used as the components template with the
   * given name. To do so it asks the resourceManager of the component for
   * a template with the given name and with the languages activate in the ctx.
   *
   * @param _name - the name of the template
   * @return a WOElement to be used as the template
   */
  func templateWithName(_ name: String) -> WOElement? {
    guard let rm = resourceManager
                ?? context?.application.resourceManager else {
      log.warn("missing resourcemanager to lookup template:", name)
      return nil
    }
    
    return rm.templateWithName(name, languages: context?.languages ?? [],
                               using: rm)
  }
  
  
  // MARK: - GoObjectRenderer

  open func rendererForObject(_ object: Any?, in context: WOContext)
            -> GoObjectRenderer?
  {
    /* We return ourselves in case we can render the given object. Which by
     * default is *off* (and you should be careful to turn it on!).
     */
    return canRenderObject(object, in: context) ? self : nil
  }
  
  open func canRenderObject(_ object: Any?, in context: WOContext) -> Bool {
    return false
  }

  /**
   * This just takes the given object using the 'setRenderObject()' method and
   * then lets the `GoDefaultRenderer` render the object as a component.
   *
   * @param _object - the object which shall be rendered
   * @param _ctx    - the rendering context
   * @return null if everything went fine, an Exception otherwise
   */
  open func renderObject(_ object: Any?, in context: WOContext) throws {
    // TODO
    if let object = object as? WOComponent {
      renderObject = object === self ? nil : object
    }
    else {
      renderObject = object
    }
    try GoDefaultRenderer.shared.renderComponent(self, in: context)
  }
  
  open var renderObject : Any? // TODO: push into extra attrs

  
  // MARK: - KVC
  
  lazy var typeInfo = try? Runtime.typeInfo(of: type(of: self))
  
  open func takeValue(_ value : Any?, forKey k: String) throws {
    if variableDictionary[k] != nil {
      if let value = value { variableDictionary[k] = value }
      else { variableDictionary.removeValue(forKey: k) }
    }
    
    switch k {
      case "context", "name", "parentComponent", "application",
           "hasSession", "session", "existingSession",
           "variableDictionary", "exposedActions", "self":
        return try handleTakeValue(value, forUnboundKey: k)
      default: break
    }
    
    if exposedActions[k] != nil {
      return try handleTakeValue(value, forUnboundKey: k)
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
    
    if let a = exposedActions[k] {
      do {
        let actionResult = try a()
        return actionResult
      }
      catch { // FIXME
        log.error("KVC action failed:", k, "error:", error)
        return nil
      }
    }
    
    switch k {
      case "context":         return context
      case "name":            return name
      case "parentComponent": return parentComponent
      case "application":     return application
      case "hasSession":      return hasSession
      case "session":         return session
      case "existingSession": return existingSession
      case "self":            return self
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
    if let n = _wcName               { ms += " name=\(n)"   }
    if let n = context?.contextID    { ms += " ctx=\(n)"    }
    if let n = _session?.sessionID   { ms += " sid=\(n)"    }
    if let n = parentComponent?.name { ms += " parent=\(n)" }
    
    if isAwake          { ms += " awake" }
    if _template == nil { ms += " no-template" }
    
    if let rm = _resourceManager { ms += " rm=\(UObject.getSimpleName(rm))" }
  }
}
