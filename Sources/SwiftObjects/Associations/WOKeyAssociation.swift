//
//  WOKeyAssociation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

public class WOKeyAssociation : WOAssociation, SmartDescription {
  
  public let key : String
  
  public init(_ key: String) {
    self.key = key
  }
  
  public var keyPath: String? { return key }

  public var isValueConstant : Bool { return false }
  public var isValueSettable : Bool { return true  }
  
  public func setValue(_ value: Any?, in component: Any?) throws {
    try KeyValueCoding.takeValue(value, forKey: key, inObject: component)
  }
  public func value(in component: Any?) -> Any? {
    return KeyValueCoding.value(forKey: key, inObject: component)
  }

  
  // MARK: - Description

  public func appendToDescription(_ ms: inout String) {
    ms.append(" key=")
    ms.append(key)
  }
}
