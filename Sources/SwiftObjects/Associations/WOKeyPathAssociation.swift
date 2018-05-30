//
//  WOKeyPathAssociation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Evaluates a KVC keypath against the current component.
 */
public class WOKeyPathAssociation : WOAssociation, SmartDescription {
  
  public let path : [ String ]
  
  public init(_ path: String) {
    self.path = path.components(separatedBy: ".")
  }
  
  public var keyPath: String? { return path.joined(separator: ".") }
  
  public var isValueConstant : Bool { return false }
  public var isValueSettable : Bool { return true  }
  
  public func setValue(_ value: Any?, in component: Any?) throws {
    try KeyValueCoding.takeValue(value, forKeyPath: path, inObject: component)
  }
  public func value(in component: Any?) -> Any? {
    return KeyValueCoding.value(forKeyPath: path, inObject: component)
  }
  
  
  // MARK: - Description
  
  public func appendToDescription(_ ms: inout String) {
    ms.append(" path=")
    ms.append(keyPath ?? "-")
  }
}
