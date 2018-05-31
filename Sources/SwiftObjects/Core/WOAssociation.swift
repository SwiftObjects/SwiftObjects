//
//  WOAssociation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Associations define how
 * dynamic elements (stateless, non-WOComponent template elements) pull and
 * push their 'bindings'.
 *
 * The most common implementors are `WOKeyPathAssociation`, which
 * pushes/pulls values into/from the current component in the context,
 * and `WOValueAssociation`, which just wraps a constant value in
 * the WOAssociation API.
 *
 * But in addition there are associations which evaluate OGNL expressions,
 * which resolve their value as localization keys or which resolve string
 * patterns in a certain context. etc etc
 */
public protocol WOAssociation : class {
  
  // MARK: - Reflection
  
  /**
   * Returns true if the association always returns the same value. This can be
   * used by dynamic elements to cache the value (and discard the association
   * wrapper).
   *
   * @return true if the value of the association never changes, false otherwise
   */
  var isValueConstant : Bool { get }
  
  /**
   * Returns true if the association accepts new values. Eg a constant
   * association obviously doesn't accept new values. A KVC association to a
   * target which does not have a <code>set</code> accessor could also return
   * false (but currently does not ...).
   *
   * @return true if the value of the association can be set, false otherwise
   */
  var isValueSettable : Bool { get }

  /**
   * Returns true if the association always returns the same value for the
   * specified cursor (usually a component). This can be used by dynamic
   * elements to cache the value.
   *
   * @return true if the value of the association does not change
   */
  func isValueConstantInComponent(_ cursor: Any?) -> Bool

  /**
   * Returns true if the association can accept new values for the given cursor
   * (usually a WOComponent). A KVC association to a target which does not have
   * a `set` accessor could also return false.
   *
   * @return true if the value of the association can be set, false otherwise
   */
  func isValueSettableInComponent(_ cursor: Any?) -> Bool
  
  var keyPath : String? { get }

  
  // MARK: - Values
  
  func setValue(_ value: Any?, in component: Any?) throws
  func value(in component: Any?) -> Any?
  
  
  // MARK: - Specific Values
  
  func setBoolValue(_ value: Bool, in component: Any?) throws
  func boolValue(in component: Any?) -> Bool
  
  func setIntValue(_ value: Int, in component: Any?) throws
  func intValue(in component: Any?) -> Int
  
  func setStringValue(_ value: String?, in component: Any?) throws
  func stringValue(in component: Any?) -> String?
}


// MARK: - Default implementation

public extension WOAssociation {

  public var isValueConstant : Bool { return false }
  public var isValueSettable : Bool { return true }
  
  public func isValueConstantInComponent(_ cursor: Any?) -> Bool {
    return isValueConstant
  }
  public func isValueSettableInComponent(_ cursor: Any?) -> Bool {
    return isValueSettable
  }
  
  public var keyPath : String? { return nil }
  
  
  // MARK: - Values
  
  public func setValue(_ value: Any?, in component: Any?) {
    // TBD: we could throw, but GETobjects used to be quite forgiving ;-)
  }
  public func value(in component: Any?) -> Any? {
    return nil
  }
  
  
  // MARK: - Specific Values
  
  func setBoolValue(_ value: Bool, in component: Any?) throws {
    try setValue(value, in: component)
  }
  func boolValue(in component: Any?) -> Bool {
    return UObject.boolValue(value(in: component))
  }
  
  func setIntValue(_ value: Int, in component: Any?) throws {
    try setValue(value, in: component)
  }
  func intValue(in component: Any?) -> Int {
    return UObject.intValue(value(in: component))
  }
  
  func setStringValue(_ value: String?, in component: Any?) throws {
    try setValue(value, in: component)
  }
  func stringValue(in component: Any?) -> String? {
    guard let v = value(in: component) else { return nil }
    return (v as? String) ?? String(describing: v)
  }
}
