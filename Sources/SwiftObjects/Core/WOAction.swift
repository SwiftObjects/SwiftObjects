//
//  WOAction.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018-2021 ZeeZide. All rights reserved.
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


// MARK: - Circus to map Swift methods to Strings.

/*
 * Note: let me know if there is a better way to do this.
 *
 * FIXME: The other bug w/ this is that this should really be a one-time, type
 *        specific thing. (i.e. something static)
 *
 * This is what I want (leaving alone proper Reflection in Swift):
 *
 *     init(context: WOContext) {
 *       expose(defaultAction, as: "default")
 *     }
 *
 * An issue is that using `self.abc` returns a bound function (captures self).
 *
 * An ugly option is this:
 *
 *     init(context: WOContext) {
 *       expose({ [weak self] in self?.defaultAction(), as: "default")
 *     }
 *
 * But this is not really what we'd do in WO, but more like a route.
 *
 * So for now this does:
 *
 *     init(context: WOContext) {
 *       expose(DirectAction.defaultAction, as: "default")
 *     }
 *
 * Well, actually we can break cycles in `sleep` or after performing an action,
 * they have definite life times.
 * But this means component-actions should be registered in awake.
 */
public protocol WOActionMapper : AnyObject {
  
  /// An action takes no own parameters, and returns a result. Or throws.
  typealias WOActionCallback = () throws -> Any?

  /**
   * Explicitly expose an action method to the Web.
   *
   * Example DirectAction:
   *
   *     init(context: WOContext) {
   *         super.init(context: context)
   *         expose(defaultAction, as: "default")
   *         expose(sayHello,      as: "hello")
   *     }
   *
   * Component:
   *
   *     override func awake() {
   *         super.awake()
   *         expose(defaultAction, as: "default")
   *     }
   */
  func expose(_ cb: @escaping WOActionCallback, as name: String)
  
  func lookupActionNamed(_ name: String) -> WOActionCallback?
  
  var exposedActions : [ String : WOActionCallback ] { get set }
    // Note: this usually creates a cycle!
}

public extension WOActionMapper { // default imp

  func expose(_ cb: @escaping WOActionCallback, as name: String) {
    exposedActions[name] = cb
  }
  
  func lookupActionNamed(_ name: String) -> WOActionCallback? {
    guard let method = exposedActions[name] else { return nil }
    return method
  }
}

public extension WOActionMapper { // helper to support non-throwing actions

  /// An action that takes no own parameters, and returns a result.
  func expose(_ cb: @escaping () -> Any?, as name: String) {
    // I guess `rethrows` can do this too? No idea :-)
    func makeThrowing() throws -> Any? {
      return cb()
    }
    expose(makeThrowing, as: name)
  }
}
