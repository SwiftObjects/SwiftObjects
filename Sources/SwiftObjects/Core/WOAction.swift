//
//  WOAction.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

public protocol WOAction {
  // TODO: document
  // - only relevant subclass: WODirectAction?
  
  var context         : WOContext  { get }
  var request         : WORequest  { get }
  
  var existingSession : WOSession? { get }
  var session         : WOSession  { get }
  
  func pageWithName(_ name: String) -> WOComponent?
  
  func performActionNamed(_ name: String) throws -> Any?
}

public extension WOAction {

  var request : WORequest { return context.request }
  var session : WOSession { return context.session }

  var existingSession : WOSession? {
    return context.hasSession ? context.session : nil
  }

  func pageWithName(_ name: String) -> WOComponent? {
    return context.application.pageWithName(name, in: context)
  }
}


// MARK: - Mapping Swift methods to action names.

/**
 * Maps action names, strings, to Swift methods.
 *
 * We can't use reflection in Swift like in Java/ObjC, but we can now generate
 * reflection info using Swift macros. For KVC and for method calls.
 * ```swift
 * @WODirectAction // <= this does the magic
 * final class DirectAction {
 *   func helloAction() -> Any? { ... }
 * }
 * ```
 *
 * There are two kinds of actions. Component actions are bound in templates
 * (e.g. `<wo:form action="$save">`) and invoked by the component action request
 * handler based on the element-id path.
 * Direct actions are invoked by name, e.g. in the URL `/Mehr.app/wa/Main/hi`,
 * i.e. they are directly exposed to the client.
 *
 * Methods are either marked as actions (made callable) using the `@WOAction`
 * macro, like `@WOAction func hi() { ... }`, or by having an `Action` suffix,
 * like `func hiAction() {}`.
 * If the method ends in "Action" they are available as direct actions (exposed
 * by name). If not, they become component actions.
 * E.g. `@WOAction func hi() {}` wouldn't be available as `/wa/Main/hi`.
 */
public protocol WOActionMapper : AnyObject {
  
  /// An action takes no own parameters, and returns a result. Or throws.
  typealias WOActionCallback = () throws -> Any?

  /**
   * Manually expose an action closure to the Web.
   *
   * Prefer the overloads taking an unbound method reference, like
   * `expose(Self.sayHello, as: "hello")`, those do not capture `self`. A
   * closure passed here which captures `self` creates a retain cycle, as the
   * closure is stored in the object. Use `[weak self]` in that case.
   *
   * - Parameters:
   *   - callback: The closure invoking the action
   *   - name:     Name of the action.
   *   - direct:   Whether the action can be invoked by the client using a
   *               direct action URL, defaults to false
   */
  func expose(_ callback: @escaping WOActionCallback, as name: String,
              direct: Bool)
  
  /**
   * Returns the callback for the action with the given name, or nil if there
   * is no such action. Finds *all* actions by name, direct or not.
   */
  func lookupActionNamed(_ name: String) -> WOActionCallback?
  
  /**
   * Returns the callback for the direct action with the given name, or nil
   * if the action does not exist or cannot be invoked using a direct action
   * URL.
   */
  func lookupDirectActionNamed(_ name: String) -> WOActionCallback?
  
  /// The actions exposed manually, by name.
  var exposedActions : [ String : WOExposedAction ] { get set }
}

/**
 * An action exposed manually using ``WOActionMapper/expose(_:as:direct:)``.
 * Carries whether the action is a direct action, i.e. whether the client can
 * invoke it by name.
 *
 * The action is stored as a closure taking the object to invoke it on, so
 * that it doesn't need to capture the object. Otherwise the object would
 * retain itself through its `exposedActions`.
 */
public struct WOExposedAction {
  
  /// Whether the action can be invoked using a direct action URL.
  public let isDirect : Bool
  
  /// Invokes the action on the given object.
  public let invoke   : (AnyObject) throws -> Any?
  
  public init(isDirect: Bool, invoke: @escaping (AnyObject) throws -> Any?) {
    self.isDirect = isDirect
    self.invoke   = invoke
  }
}

public extension WOActionMapper { // default imp

  /**
   * Exposes an unbound method as an action.
   * ```swift
   * func awake() {
   *   expose(Self.sayHello, as: "hello")              // component action
   *   expose(Self.showAll,  as: "all", direct: true)  // /wa/Main/all
   * }
   * ```
   *
   * - Parameters:
   *   - method: an unbound method reference, like `Self.sayHello`
   *   - name:   the name of the action
   *   - direct: whether the action can be invoked by the client using a
   *             direct action URL, defaults to false
   */
  func expose(_ method: @escaping ( Self ) -> () throws -> Any?,
              as name: String, direct: Bool = false)
  {
    exposedActions[name] = WOExposedAction(isDirect: direct) { object in
      guard let target = object as? Self else {
        assertionFailure("invoking action \(name) on wrong object")
        return nil
      }
      return try method(target)()
    }
  }
  
  /**
   * Exposes an unbound method as an action.
   * ```swift
   * func awake() {
   *   expose(Self.sayHello, as: "hello")              // component action
   *   expose(Self.showAll,  as: "all", direct: true)  // /wa/Main/all
   * }
   * ```
   *
   * - Parameters:
   *   - method: an unbound method reference, like `Self.sayHello`
   *   - name:   the name of the action
   *   - direct: whether the action can be invoked by the client using a
   *             direct action URL, defaults to false
   */
  func expose(_ method: @escaping ( Self ) -> () throws -> Void,
              as name: String, direct: Bool = false)
  {
    expose({ (target: Self) in { try method(target)(); return nil } },
           as: name, direct: direct)
  }
  
  func expose(_ cb: @escaping WOActionCallback, as name: String,
              direct: Bool = false)
  {
    exposedActions[name] = WOExposedAction(isDirect: direct) { _ in try cb() }
  }
  
  func lookupActionNamed(_ name: String) -> WOActionCallback? {
    guard let action = exposedActions[name] else { return nil }
    return { try action.invoke(self) }
  }
}
