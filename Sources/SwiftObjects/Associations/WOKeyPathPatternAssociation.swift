//
//  WOKeyPathPatternAssociation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

/**
 * Evaluates String patterns which contain keypathes. This uses the
 * NSKeyValueStringFormatter's format() method and calls it with the given
 * pattern on the component.
 * That is, the KVC path variables inside the pattern start their evaluation
 * at the current component.
 *
 * Example:
 *
 *     <wo:get varpat:value=
 *        "Batch %(dg.currentBatchIndex)i of %(dg.batchCount)i" />
 *
 */
public class WOKeyPathPatternAssociation : WOAssociation, SmartDescription {
  
  public let pattern : String
  
  public init(_ pattern: String) {
    self.pattern = pattern
  }
  
  public var keyPath: String? { return pattern } // well, ...
  
  public var isValueConstant : Bool { return false }
  public var isValueSettable : Bool { return false }
  
  public func stringValue(in component: Any?) -> String? {
    return KeyValueStringFormatter.format(pattern, object: component)
  }
  
  public func value(in component: Any?) -> Any? {
    return stringValue(in: component)
  }
  
  
  // MARK: - Description
  
  public func appendToDescription(_ ms: inout String) {
    ms.append(" pattern=")
    ms.append(pattern)
  }
}
