//
//  WOValueAssociation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

/**
 * Represents a constant value.
 *
 * For example:
 *
 *     <wo:str value="Hello World" />
 *
 * Will result in a WOValueAssociation<String> with the constant value
 * "Hello World".
 */
public class WOValueAssociation<Element> : WOAssociation, SmartDescription {
  
  public let value : Element
  
  public init(_ value: Element) {
    self.value = value
  }
  
  public var isValueConstant : Bool { return true  }
  public var isValueSettable : Bool { return false }
  
  public func value(in component: Any?) -> Any? {
    return value
  }

  // MARK: - Description
  
  public func appendToDescription(_ ms: inout String) {
    ms.append(" value=\(value)")
  }
}

public extension WOValueAssociation where Element == String {
  
  func boolValue(in component: Any?) -> Bool { return UObject.boolValue(value) }
  func intValue (in component: Any?) -> Int  { return UObject.intValue (value) }
  func stringValue(in component: Any?) -> String? { return value }
}

public extension WOValueAssociation where Element == Bool {
  
  func boolValue(in component: Any?) -> Bool { return value }
  func intValue (in component: Any?) -> Int  { return value ? 1 : 0  }
  
  func stringValue(in component: Any?) -> String? {
    return value ? "true" : "false"
  }
}

public extension WOValueAssociation where Element == Int {
  
  func boolValue  (in component: Any?) -> Bool    { return value != 0    }
  func intValue   (in component: Any?) -> Int     { return value         }
  func stringValue(in component: Any?) -> String? { return String(value) }
}
