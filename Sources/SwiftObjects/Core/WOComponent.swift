//
//  WOComponent.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

/**
 * ``WOComponent``'s are used to represent template based pages or reusable
 * components in SwiftObjects.
 * A component (usually) is a Swift class marked with the ``WOComponent()``
 * macro plus a template. The exact format of the template depends on the
 * respective template builder, usually the ``WOWrapperTemplateBuilder`` is
 * used (html/wod in .wo bundle).
 *
 * ```swift
 * @WOComponent final class Main {
 *   var title = "Hello World"
 * }
 * ```
 *
 * The macro adds the conformance to this protocol, the storage the protocol
 * requires, the lookup of the action methods and KVC accessors for the
 * properties declared in the class. Components can inherit from other
 * components, the macro has to be applied to both classes:
 * ```swift
 * @WOComponent class CommonPage {
 *   var title = ""
 * }
 * @WOComponent final class Main : CommonPage {
 *   func awake() { title = "Main" }
 * }
 * ```
 *
 * Classes conforming to the protocol manually need to provide the storage
 * properties and the `init()`.
 *
 * ### ``WOComponent`` vs. ``WODynamicElement``
 *
 * Both, ``WOComponent`` and ``WODynamicElement``, conform to the
 * ``WOElement`` protocol. The major conceptual difference is that
 * ``WOComponent``'s have own per-transaction or per-session state while
 * ``WODynamicElement``'s have *no* own instance variable state but retrieve
 * state using WOAssociations from the active component.
 *
 * Plus WODynamicElements almost always directly render HTML/XML/xyz in Swift
 * code while ``WOComponent``'s usually have an associated template. (both are
 * not exact requirements, a ``WOComponent`` can also directly render w/o a
 * template and a ``WODynamicElement`` could load a stateless sub-template).
 *
 * ### Subcomponents
 *
 * FIXME: Explain better how subcomponents work.
 *
 * Components can refer other components in the template, like:
 * ```xml
 * <#ZideBox title="Hello" />
 * ```
 *
 * This does two things: the template will get an ``WOChildComponentReference``
 * dynamic element which represents the component in the template hierarchy,
 * AND upon instantiation the component will get an entry in its 'subcomponents'
 * Map. Usually the subcomponent will start out as a ``WOComponentFault``. Only
 * if it is actually needed, a real ``WOComponent`` instance will be created.
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
 * I think the idea is that a stateless component is like a
 * ``WODynamicElement``, with the difference, that you can use pageWithName and
 * such to look them up and have a template associated with it.
 *
 * ### Relationship to ``WOContext``
 *
 * Unless it is a stateless component a component is always associated with a
 * ``WOContext``. The ``WOContext`` tracks which components are awake and such,
 * and it tracks the current component activation chain (consider it the
 * callstack of the components).
 *
 * ### Differences to WebObjects
 *
 * #### Initialization
 *
 * Components are created using the argument-less `init()`, the context is
 * assigned afterwards using ``initWithContext(_:)``. Override that method to
 * perform per object initialization which needs the context.
 *
 * #### Go ``WOComponent``'s can be used as ``WODirectAction``'s
 *
 * In Go components can be directly used as direct actions. In traditional WO
 * one usually has a direct action, which then instantiates a ``WOComponent``,
 * passes over rendering arguments and then returns it for rendering.
 *
 * This can be reduced in Go. In Go you can directly invoke a component like
 * a direct action, sample:
 * ```swift
 * @WOComponent
 * final class Main {
 *   ...
 *   func showAction() -> Any? { ...
 * ```
 * Invoke via:
 * ```
 * /MyApp/wa/Main/show?id=5
 * ```
 *
 * All the rules of ``WODirectAction`` apply. Actions must be exposed, using
 * the ``WOComponent()`` macro or `expose(_:as:direct:)`, and if none is
 * specified, `defaultAction` is invoked. Methods with the `Action` suffix are
 * direct actions. Component actions, methods only marked with `@WOAction`, are
 * not reachable this way unless marked with `@WOAction(direct: true)`.
 *
 * #### Component specific ``WOResourceManager``'s
 *
 * In Go there is the concept of component-specific ``WOResourceManager``'s. WO
 * only has a global one (Go falls back to this if there is no local one).
 *
 * This is to support OFS and other hierarchical Go publishing setups. Example:
 * ```
 * /MyApp/persons/person/index.wo
 * /MyApp/persons/index.wo
 * /MyApp/Frame.wo
 * ```
 *
 * With the right resource manager the components can perform lookup of
 * resources relative to the position of the source component.
 *
 * #### Redirect and F()
 *
 * Go has the convenience redirectToLocation() method.
 * To retrieve form values one can use the F() methods, sample:
 * ```
 * /MyApp/wa/Persons/fetch?limit=50
 * int fetchLimit = UObject.intValue(F("limit", 10));
 * ```
 *
 * ### Integration with the Zope-like Go publishing system
 *
 * FIXME: document more.
 *
 * A ``WOComponent`` is an IGoObject, an IGoObjectRenderer and an
 * IGoObjectRendererFactory.
 *
 * FIXME: write about GoPageInvocation and how a ``WOComponent`` usually is not
 * directly part of the traversal path.
 *
 * The IGoObject implementation supports lookup of direct action methods (as
 * Go methods). Plus lookup using the Go class.
 * Sample: 'lookupName("show");' will give you a GoCallable 'showAction'.
 *
 * Careful: If you invoke a page like this:
 * ```
 * /MyApp/wa/Main/show?id=5
 * ```
 *
 * the Go method is 'wa', the ``WODirectActionRequestHandler``.
 * This is why permissions on the ``WOComponent``'s are not checked here, the
 * component is not part of the Go lookup.
 */
public protocol WOComponent : WOElement, WOActionResults, WOLifecycle,
                              GoObjectRenderer, GoObjectRendererFactory,
                              ExtraVariables, WOActionMapper,
                              KeyValueCodingType, MutableKeyValueCodingType,
                              SmartDescription
{

  /**
   * Creates the component. Components are instantiated without arguments,
   * the context is assigned afterwards using ``initWithContext(_:)``.
   */
  init()

  // MARK: - Storage

  /// The logger of the component, usually the one of the application.
  var log : WOLogger { get set }

  /**
   * The name assigned by the component definition, which can differ from the
   * class name (e.g. for templates w/o a class).
   */
  var _wcName : String? { get set }

  /**
   * Returns the ``WOContext`` the component was created in. The ``WOContext``
   * provides access to the request and response objects, to the session, and so
   * on.
   */
  var context : WOContext? { get set }

  /// The session the component was awoken in, if any.
  var _session : WOSession? { get set }

  /// The child components, by the names used in the template.
  var subcomponents : [ String : WOComponent ] { get set }

  /// The bindings of a child component, as declared in the parent template.
  var wocBindings : [ String : WOAssociation ] { get set }

  /// The component this component is a child of, if any.
  var parentComponent : WOComponent? { get set }

  /// Whether the component is stateless, i.e. reset after each use.
  var isStateless : Bool { get }

  /// Whether the component received its `awake()`.
  var isAwake : Bool { get set }

  /// A specific resource manager assigned to the component, usually nil.
  var _resourceManager : WOResourceManager? { get set }

  /// A specific template assigned to the component, usually nil.
  var _template : WOElement? { get set }

  /// The object being rendered, if the component is used as a renderer.
  var renderObject : Any? { get set }


  // MARK: - Hooks

  /**
   * Initialize the component in the given context. Override this instead of
   * the initializer to perform per object initialization.
   *
   * - Parameters:
   *   - ctx:   the ``WOContext``
   * - Returns: the component this was invoked on, or optionally a replacement
   */
  func initWithContext(_ ctx: WOContext) -> WOComponent?

  /// The name of the component, defaults to the name of the class.
  var name : String { get }

  /**
   * This method is called once per instance and context before the component
   * is being used. It can be used to perform 'late' initialization.
   */
  func awake()

  /// This is called when the component is put into sleep.
  func sleep()

  /// Called to reset the state of stateless components.
  func reset()

  /**
   * Looks up and instantiates a new component with the given name. The default
   * implementation just forwards the call to the ``WOApplication`` object.
   */
  func pageWithName(_ name: String) -> WOComponent?

  /**
   * Invokes the direct action with the given name, see
   * ``WODirectAction/performActionNamed(_:)``.
   */
  func performActionNamed(_ name: String) throws -> Any?

  /**
   * Returns the callback for the action with the given name, or nil if the
   * action is not exposed.
   *
   * Classes marked with ``WOComponent()`` get a generated implementation
   * mapping the action methods of the class. The default implementation
   * checks the actions exposed using `expose(_:as:direct:)` and `default`.
   *
   * - Parameters:
   *   - name: the name of the action, e.g. `show`
   * - Returns: the callback invoking the action, nil if there is none
   */
  func lookupActionNamed(_ name: String) -> WOActionCallback?

  /**
   * Returns the callback for the direct action with the given name, i.e. an
   * action which can be invoked using a URL like `/MyApp/wa/Main/show`.
   *
   * This only covers actions exposed using `expose(_:as:direct:)` with
   * `direct: true`, `default`, and in classes marked with ``WOComponent()``
   * the methods with the `Action` suffix and the ones marked with
   * `@WOAction(direct: true)`. Component actions, methods only marked with
   * `@WOAction` or exposed without `direct: true`, are not direct actions,
   * they can only be triggered by template bindings.
   *
   * - Parameters:
   *   - name: the name of the action, e.g. `show`
   * - Returns: the callback invoking the action, nil if there is none
   */
  func lookupDirectActionNamed(_ name: String) -> WOActionCallback?

  /// The action invoked for `default`, returns the component itself.
  func defaultAction() -> WOComponent?

  /**
   * Whether the take-values phase should run for the request. The default
   * returns true for POST requests and requests with form values.
   */
  func shouldTakeValues(from request: WORequest, in context: WOContext)
       -> Bool

  /**
   * This method returns whether bindings are automatically synchronized between
   * parent and child components. Per default this returns true, but
   * subcomponents can decide to return false and grab their bindings manually.
   *
   * Example:
   * ```wod
   * Child: MyChildComponent {
   *   name = title;
   * }
   * ```
   *
   * The 'title' value of the component will be copied into the 'name' value of
   * the child if the child is entered. And its copied back when the child is
   * left.
   */
  var synchronizesVariablesWithBindings : Bool { get }

  /// Called by form elements if a value could not be validated.
  func validationFailed(with error: Swift.Error, value: Any?, keyPath: String?)

  /**
   * Returns whether the component can render the given object, used when the
   * component acts as a ``GoObjectRenderer``. Off by default.
   */
  func canRenderObject(_ object: Any?, in context: WOContext) -> Bool
}

public extension WOComponent {

  func initWithContext(_ ctx: WOContext) -> WOComponent? {
    return woInitWithContext(ctx)
  }

  /**
   * The implementation of ``initWithContext(_:)``, assigns the context and
   * the logger. Classes marked with ``WOComponent()`` call this from the
   * generated method, classes overriding the method should call it too.
   */
  func woInitWithContext(_ ctx: WOContext) -> WOComponent? {
    self.context = ctx
    self.log     = ctx.application.log
    return self
  }

  var application : WOApplication? {
    return context?.application
  }

  var name : String { return woName }

  /// The implementation of ``name``, the assigned name or the class name.
  var woName : String {
    return _wcName ?? UObject.getSimpleName(self)
  }
  
  
  // MARK: - Form Values
  
  /**
   * Dirty convenience hack to return the value of a form parameter.
   * Sample:
   * ```swift
   * let fetchLimit = UObject.intValue(F("limit"))
   * ```
   *
   * - Parameters:
   *   - name:  name of a form field or query parameter
   * - Returns: value of the field or nil if it was not found
   */
  func F(_ name: String, default: Any? = nil) -> Any? {
    return context?.request.formValue(for: name) ?? `default`
  }
  
  
  // MARK: - Livecycle

  var isStateless : Bool { return false }

  func awake() {}
  func reset() {}
  func sleep() {}

  /**
   * Internal method to ensure that the ``WOComponent`` received its awake()
   * message and that the internal state of the component is properly setup.
   * This is called by other parts of the framework before the component is
   * used.
   *
   * - Parameters:
   *   - context: the ``WOContext``
   */
  func ensureAwake(in context: WOContext) {
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
   * - Parameters:
   *   - context: the ``WOContext`` to awake in
   */
  func _awakeWithContext(_ context: WOContext) {
    // TBD: we do we have _awakeWithContext() and ensureAwakeInContext()?
    /* this is called by the framework to awake the component */
    if !isAwake { // hm, flag useful/necessary? Tracked in context?
      ensureAwake(in: context)
    }
  }
  
  func _sleepWithContext(_ context: WOContext) {
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

  func pageWithName(_ name: String) -> WOComponent? {
    return woPageWithName(name)
  }

  /**
   * The implementation of ``pageWithName(_:)``, asks the ``WOApplication``.
   * Classes marked with ``WOComponent()`` call this from the generated
   * method.
   */
  func woPageWithName(_ name: String) -> WOComponent? {
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
   * This method implements the ``WOActionResults`` protocol for
   * ``WOComponent``. It creates a new ``WOResponse`` and calls appendToResponse
   * on that response.
   *
   * - Returns: a ``WOResponse`` containing the rendering of the ``WOComponent``
   */
  func generateResponse() throws -> WOResponse {
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

  func performActionNamed(_ name: String) throws -> Any? {
    return try woPerformActionNamed(name)
  }

  /**
   * The implementation of ``performActionNamed(_:)``. Classes marked with
   * ``WOComponent()`` call this from the generated method.
   */
  func woPerformActionNamed(_ name: String) throws -> Any? {
    guard let context = context else {
      log.error("component invoked as direct-action has no context assigned:",
                self)
      throw WOComponentError.componentInvokedAsDirectActionMissesContext(name)
    }
    return try WODirectActionRequestHandler
                 .performActionNamed(name, on: self, in: context)
  }

  func lookupActionNamed(_ name: String) -> WOActionCallback? {
    return woLookupActionNamed(name)
  }

  func lookupDirectActionNamed(_ name: String) -> WOActionCallback? {
    return woLookupDirectActionNamed(name)
  }

  /**
   * The implementation of ``lookupActionNamed(_:)``. Classes marked with
   * ``WOComponent()`` fall back to this in the generated method.
   *
   * The actions exposed using `expose(_:as:direct:)` are checked first,
   * then the `default` action is mapped to ``defaultAction()``.
   */
  func woLookupActionNamed(_ name: String) -> WOActionCallback? {
    if let action = exposedActions[name] { return { try action.invoke(self) } }
    if name == WODirectActionRequestHandler.defaultActionName {
      return { self.defaultAction() }
    }
    return nil
  }

  /**
   * The implementation of ``lookupDirectActionNamed(_:)``. Classes marked
   * with ``WOComponent()`` fall back to this in the generated method.
   *
   * Only the actions exposed with `direct: true` and `default` are direct
   * actions.
   */
  func woLookupDirectActionNamed(_ name: String) -> WOActionCallback? {
    if let action = exposedActions[name] {
      return action.isDirect ? { try action.invoke(self) } : nil
    }
    if name == WODirectActionRequestHandler.defaultActionName {
      return { self.defaultAction() }
    }
    return nil
  }

  func defaultAction() -> WOComponent? {
    return self
  }


  // MARK: - Responder

  func shouldTakeValues(from request: WORequest, in context: WOContext)
       -> Bool
  {
    return woShouldTakeValues(from: request, in: context)
  }

  /// The implementation of ``shouldTakeValues(from:in:)``.
  func woShouldTakeValues(from request: WORequest, in context: WOContext)
       -> Bool
  {
    return request.method == "POST" || request.hasFormValues
  }

  func takeValues(from request: WORequest, in context: WOContext) throws {
    try woTakeValues(from: request, in: context)
  }

  func invokeAction(for request: WORequest, in context: WOContext) throws
       -> Any?
  {
    return try woInvokeAction(for: request, in: context)
  }

  func append(to response: WOResponse, in context: WOContext) throws {
    try woAppend(to: response, in: context)
  }

  func walkTemplate(using walker: WOElementWalker, in context: WOContext)
         throws
  {
    try woWalkTemplate(using: walker, in: context)
  }

  /// The implementation of `takeValues(from:in:)`, runs the template.
  func woTakeValues(from request: WORequest, in context: WOContext) throws {
    assert(isAwake, "component not awake?")
    try template?.takeValues(from: request, in: context)
  }

  /// The implementation of `invokeAction(for:in:)`, runs the template.
  func woInvokeAction(for request: WORequest, in context: WOContext) throws
       -> Any?
  {
    assert(isAwake, "component not awake?")
    let result = try template?.invokeAction(for: request, in: context)
    return result
  }

  /// The implementation of `append(to:in:)`, runs the template.
  func woAppend(to response: WOResponse, in context: WOContext) throws {
    assert(isAwake, "component not awake?")
    try template?.append(to: response, in: context)
    if isStateless { reset() }
  }

  /// The implementation of `walkTemplate(using:in:)`, runs the template.
  func woWalkTemplate(using walker: WOElementWalker, in context: WOContext)
         throws
  {
    assert(isAwake, "component not awake?")
    if let template = template {
      _ = try walker(self, template, context)
    }
    if isStateless { reset() }
  }

  
  // MARK: - Component Synchronization

  var synchronizesVariablesWithBindings : Bool {
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
   * - Parameters:
   *   - parent: the parent component to copy values from
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
   * - Parameters:
   *   - parent: the parent component to copy values to
   */
  func sync(to parent: WOComponent) { /* SOPE method */
    let lvalues = values(forKeys: Array(wocBindings.keys))
    
    for ( bindingName, binding ) in wocBindings {
      guard binding.isValueSettableInComponent(parent) else { continue }
      try? binding.setValue(lvalues[bindingName], in: parent)
    }
  }

  func hasBinding(_ name: String) -> Bool {
    return wocBindings[name] != nil
  }

  func canGetValueForBinding(_ name: String) -> Bool {
    guard let a = wocBindings[name] else { return false }
    return a.isValueSettableInComponent(parentComponent)
  }

  var bindingKeys : [ String ] {
    return Array(wocBindings.keys)
  }
  
  /**
   * This invokes a bound method in the context of the parent component. Calling
   * this will sync back to the parent, invoke the method and then sync down to
   * the child.
   *
   * - Parameters:
   *   - name:  name of the bound parent method
   * - Returns: the result of the called method
   */
  func performParentAction(_ name: String) -> Any? {
    let ctx = context
    ctx?.leaveComponent(self)
    let result = KeyValueCoding.value(forKey: name, inObject: parentComponent)
    ctx?.enterComponent(self)
    return result
  }

  func childComponent(with name: String) -> WOComponent? {
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
   * has an active ``WOSession``.
   *
   * - Returns: true if a session is active, false otherwise
   */
  var hasSession : Bool {
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
   * - Returns: an old or new ``WOSession``
   */
  var session : WOSession? {
    if let sn = _session { return sn }
    return context?.session // creates one on demand!
  }

  var existingSession : WOSession? {
    return hasSession ? session : nil
  }
  
  
  // MARK: - Validation

  func validationFailed(with error: Swift.Error, value: Any?,
                        keyPath: String?)
  {
    // can be used in subclasses
  }

  func validationFailed(with error: Swift.Error) {
    validationFailed(with: error, value: nil, keyPath: nil)
  }


  // MARK: - Resource Manager

  /**
   * The resource manager of the component. This manager is used to lookup
   * subcomponents or other kinds of resources, like images or translations.
   *
   * Usually you do NOT have a specific resource manager but use the global
   * ``WOApplication`` manager for all components. If no specific one is
   * assigned, this returns the global one of the ``WOApplication``.
   */
  var resourceManager : WOResourceManager? {
    set { _resourceManager = newValue }
    get { return _resourceManager ?? application?.resourceManager }
  }


  // MARK: - Templates

  /**
   * The ``WOElement`` which is being used as the template of the component.
   * Usually no specific template is assigned, in which case it is retrieved
   * dynamically from the ``WOResourceManager`` using the name of the
   * component.
   */
  var template : WOElement? {
    set { _template = newValue }
    get {
      if let t = _template { return t }
      // TODO: somehow this fails if the component was not instantiated using
      //       pageWithName()
      return templateWithName(name)
    }
  }
  
  /**
   * This returns the ``WOElement`` to be used as the components template with
   * the given name. To do so it asks the resourceManager of the component for a
   * template with the given name and with the languages activate in the ctx.
   *
   * - Parameters:
   *   - name:  the name of the template
   * - Returns: a ``WOElement`` to be used as the template
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

  func rendererForObject(_ object: Any?, in context: WOContext)
       -> GoObjectRenderer?
  {
    /* We return ourselves in case we can render the given object. Which by
     * default is *off* (and you should be careful to turn it on!).
     */
    return canRenderObject(object, in: context) ? self : nil
  }

  func canRenderObject(_ object: Any?, in context: WOContext) -> Bool {
    return false
  }

  /**
   * This just takes the given object using the 'setRenderObject()' method and
   * then lets the ``GoDefaultRenderer`` render the object as a component.
   *
   * - Parameters:
   *   - object:  the object which shall be rendered
   *   - context: the rendering context
   */
  func renderObject(_ object: Any?, in context: WOContext) throws {
    // TODO
    if let object = object as? WOComponent {
      renderObject = object === self ? nil : object
    }
    else {
      renderObject = object
    }
    try GoDefaultRenderer.shared.renderComponent(self, in: context)
  }


  // MARK: - KVC

  func takeValue(_ value : Any?, forKey k: String) throws {
    try woTakeValue(value, forKey: k)
  }

  func value(forKey k: String) -> Any? {
    return woValue(forKey: k)
  }

  /**
   * The implementation of `takeValue(_:forKey:)`. Classes marked with
   * ``WOComponent()`` fall back to this in the generated method, which
   * covers the properties declared in the class.
   *
   * Values for unknown keys are stored in the `variableDictionary`.
   */
  func woTakeValue(_ value : Any?, forKey k: String) throws {
    if variableDictionary[k] != nil {
      if let value = value { variableDictionary[k] = value }
      else { variableDictionary.removeValue(forKey: k) }
      return
    }
    
    switch k {
      case "context", "name", "parentComponent", "application",
           "hasSession", "session", "existingSession",
           "variableDictionary", "exposedActions", "self":
        return try handleTakeValue(value, forUnboundKey: k)
      default: break
    }

    if lookupActionNamed(k) != nil {
      return try handleTakeValue(value, forUnboundKey: k)
    }

    if try defaultTakeValueForKey(value, forKey: k) { return }

    variableDictionary[k] = value
  }

  /**
   * The implementation of `value(forKey:)`. Classes marked with
   * ``WOComponent()`` fall back to this in the generated method, which
   * covers the properties declared in the class.
   *
   * Actions are invoked when accessed as a key, this is how `action`
   * bindings like `action="$save"` resolve. Then the component properties
   * are checked, and finally the `variableDictionary`.
   */
  func woValue(forKey k: String) -> Any? {
    if let a = lookupActionNamed(k) {
      do    { return try a() }
      catch { log.error("KVC action failed:", k, "error:", error); return nil }
    }

    // Handle computed/weak properties not found by typeInfo
    switch k {
      case "context":         return context  // weak reference
      case "name":            return name
      case "application":     return application
      case "hasSession":      return hasSession
      case "session":         return session
      case "existingSession": return existingSession
      case "self":            return self
      default: break
    }

    return defaultValueForKey(k)
  }

  
  // MARK: - Description

  func appendToDescription(_ ms: inout String) {
    woAppendToDescription(&ms)
  }

  /**
   * The implementation of `appendToDescription(_:)`. Classes marked with
   * ``WOComponent()`` call this from the generated method.
   */
  func woAppendToDescription(_ ms: inout String) {
    if let n = _wcName               { ms += " name=\(n)"   }
    if let n = context?.contextID    { ms += " ctx=\(n)"    }
    if let n = _session?.sessionID   { ms += " sid=\(n)"    }
    if let n = parentComponent?.name { ms += " parent=\(n)" }
    
    if isAwake          { ms += " awake" }
    if _template == nil { ms += " no-template" }
    
    if let rm = _resourceManager { ms += " rm=\(UObject.getSimpleName(rm))" }
  }
}

enum WOComponentError : Swift.Error {
  case componentInvokedAsDirectActionMissesContext(String)
}


/**
 * The component class used for templates which have no Swift class of their
 * own, e.g. a `Frame.html` without a `Frame` class. All values are kept in
 * the `variableDictionary`.
 */
@WOComponent
public final class WOTemplateComponent {}
