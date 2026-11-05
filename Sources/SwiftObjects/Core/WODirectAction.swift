//
//  WODirectAction.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

/**
 * A ``WODirectAction`` object is pretty much like a servlet, it can accept
 * requests and is responsible for producing a result. The result can be
 * either a ``WOResponse`` or a ``WOComponent`` or anything else which can be
 * rendered by SwiftObjects.
 *
 * Sample:
 * ```swift
 * @WODirectAction
 * final class DirectAction {
 *
 *   func helloAction() -> Any? {           // /MyApp/wa/DirectAction/hello
 *     return "Hello World"
 *   }
 * }
 * ```
 *
 * The request handler instantiates the class using ``init(context:)`` and
 * invokes ``performActionNamed(_:)`` with the action name from the URL. The
 * action named `default` is served by ``defaultAction()``.
 *
 * Classes conforming manually need to provide the storage properties and the
 * initializer, everything else has a default implementation.
 */
public protocol WODirectAction : WOAction, SmartDescription,
                                 KeyValueCodingType, MutableKeyValueCodingType,
                                 ExtraVariables, WOActionMapper
{

  /**
   * Creates the direct action for the given context. The request handler
   * creates a new instance for every request.
   *
   * - Parameters:
   *   - context: the ``WOContext`` of the request
   */
  init(context: WOContext)

  /// The logger of the application the action runs in.
  var log : WOLogger { get }

  /**
   * The action invoked if the URL doesn't specify an action, or specifies
   * `default`. The default implementation returns the `Main` page.
   *
   * - Returns: the result of the action, usually a ``WOComponent``
   */
  func defaultAction() -> WOActionResults?

  /**
   * Returns the callback for the action with the given name, or nil if there
   * is no such action.
   *
   * Classes marked with ``WODirectAction()`` get a generated implementation
   * which maps the action methods of the class. The default implementation
   * checks the actions exposed using `expose(_:as:direct:)` and `default`.
   *
   * - Parameters:
   *   - name: the name of the action, e.g. `default`
   * - Returns: the callback invoking the action, nil if there is none
   */
  func lookupActionNamed(_ name: String) -> WOActionCallback?

  /**
   * Returns the callback for the direct action with the given name. All
   * actions of a ``WODirectAction`` are direct actions, the default
   * implementation just calls ``lookupActionNamed(_:)``.
   *
   * - Parameters:
   *   - name: the name of the action, e.g. `default`
   * - Returns: the callback invoking the action, nil if there is none
   */
  func lookupDirectActionNamed(_ name: String) -> WOActionCallback?

  /**
   * Invokes the action with the given name and returns its result.
   *
   * The default implementation looks up the action using
   * ``lookupDirectActionNamed(_:)``, and falls back to the KVC key
   * `name + "Action"` if there is none.
   *
   * - Parameters:
   *   - name:  the name of the action, e.g. `default`
   * - Returns: the result of the action, usually a ``WOComponent`` or a
   *            ``WOResponse``
   */
  func performActionNamed(_ name: String) throws -> Any?
}

public extension WODirectAction {

  func defaultAction() -> WOActionResults? {
    return pageWithName("Main")
  }

  func performActionNamed(_ name: String) throws -> Any? {
    return try woPerformActionNamed(name)
  }

  /**
   * The implementation of ``performActionNamed(_:)``. Classes marked with
   * ``WODirectAction()`` call this from the generated method.
   */
  func woPerformActionNamed(_ name: String) throws -> Any? {
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
   * ``WODirectAction()`` fall back to this in the generated method.
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
   * with ``WODirectAction()`` fall back to this in the generated method.
   * All actions of a direct action are direct, including the ones exposed
   * manually, regardless of their `direct` flag.
   */
  func woLookupDirectActionNamed(_ name: String) -> WOActionCallback? {
    return lookupActionNamed(name)
  }

  /**
   * Iterates over the given keys and invokes takeValueForKey for each key,
   * using a similiar named form values as the value.
   */
  func takeFormValueArraysForKeyArray(_ keys : [ String ]) {
    let req = request
    
    var values = [ String : Any? ]()
    for key in keys {
      values[key] = req.formValue(for: key)
    }
    
    try? takeValuesForKeys(values)
  }

  func takeFormValuesForKeys(_ keys : String...) {
    takeFormValueArraysForKeyArray(keys)
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
   * ``WODirectAction()`` fall back to this in the generated method, which
   * covers the properties declared in the class.
   *
   * Values for unknown keys are stored in the `variableDictionary`.
   */
  func woTakeValue(_ value : Any?, forKey k: String) throws {
    if variableDictionary[k] != nil {
      if let value = value { variableDictionary[k] = value }
      else { variableDictionary.removeValue(forKey: k) }
    }

    switch k {
      case "context", "request",
           "session", "existingSession",
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
   * ``WODirectAction()`` fall back to this in the generated method, which
   * covers the properties declared in the class.
   *
   * Actions are invoked when accessed as a key. Then the context properties
   * are checked, and finally the `variableDictionary`.
   */
  func woValue(forKey k: String) -> Any? {
    // Check exposed actions (special to WODirectAction)
    if let a = lookupActionNamed(k) {
      do    { return try a() }
      catch { log.error("KVC action failed:", k, "error:", error); return nil }
    }

    // Handle computed properties not found by typeInfo
    switch k {
      case "context":         return context
      case "request":         return request
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
   * ``WODirectAction()`` call this from the generated method.
   */
  func woAppendToDescription(_ ms: inout String) {
    ms += " ctx=\(context.contextID)"
    if variableDictionary.count > 0 {
      ms += " #vars=\(variableDictionary.count)"
    }
    if exposedActions.count > 0 {
      ms += " exposes=\(exposedActions.keys)"
    }
  }
}


/**
 * The direct action used by the ``WODirectActionRequestHandler`` when the
 * application provides no `DirectAction` class of its own. It only serves
 * the `default` action, which returns the `Main` page.
 */
@WODirectAction
public final class WODefaultDirectAction {}
