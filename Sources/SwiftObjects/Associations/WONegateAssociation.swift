//
//  WONegateAssociation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * This method 'negates' the result of another association.
 *
 * Example:
 * ```
 * <wo:if not:disabled="adminArea">...</wo:if>
 * ```
 */
public class WONegateAssocation : WOAssociation, SmartDescription {
  
  public let association : WOAssociation
  
  public init(_ association : WOAssociation) {
    self.association = association
  }
  
  public var keyPath: String? {
    guard let kp = association.keyPath else { return nil }
    return "!" + kp
  }
  
  public var isValueConstant : Bool { return association.isValueConstant }
  public var isValueSettable : Bool { return false }
  
  public func isValueConstantInComponent(_ cursor: Any?) -> Bool {
    return association.isValueConstantInComponent(cursor)
  }
  public func isValueSettableInComponent(_ cursor: Any?) -> Bool {
    return false
  }

  // MARK: - Values
  
  public func setValue(_ value: Any?, in component: Any?) throws {
    try setBoolValue(UObject.boolValue(value), in: component)
  }
  public func value(in component: Any?) -> Any? {
    return boolValue(in: component)
  }
  
  
  // MARK: - Specific Values
  
  public func setBoolValue(_ value: Bool, in component: Any?) throws {
    try association.setBoolValue(!value, in: component)
  }
  public func boolValue(in component: Any?) -> Bool {
    return association.boolValue(in: component)
  }
  
  public func intValue(in component: Any?) -> Int {
    return boolValue(in: component) ? 1 : 0
  }
  public func stringValue(in component: Any?) -> String? {
    return boolValue(in: component) ? "true" : "false"
  }

  
  // MARK: - Description
  
  public func appendToDescription(_ ms: inout String) {
    ms.append(" base=\(association)")
  }
}

