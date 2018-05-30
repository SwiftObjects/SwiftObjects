//
//  WODynamicKeyPathAssociation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * This association resolves its given String using KVC to another String which
 * is then evaluated again via KVC. Weird, eh? ;-)
 */
public class WODynamicKeyPathAssociation : WOAssociation, SmartDescription {
  
  public let keyAssociation : WOAssociation
  
  public init(_ keyPath: String) {
    self.keyAssociation =
      WOAssociationFactory.associationWithKeyPath(keyPath)!
  }
  public init(_ keyAssociation: WOAssociation) {
    self.keyAssociation = keyAssociation
  }
  
  public var keyPath: String? { return "eval(\(keyAssociation)" } // well, ...
  
  public var isValueConstant : Bool { return false }
  public var isValueSettable : Bool { return false }
  
  public func value(in component: Any?) -> Any? {
    guard let keyPath = keyAssociation.stringValue(in: component) else {
      return nil
    }
    
    return KeyValueCoding.value(forKeyPath: keyPath, inObject: component)
  }
  
  
  // MARK: - Description
  
  public func appendToDescription(_ ms: inout String) {
    ms.append(" eval=\(keyAssociation)")
  }
}
