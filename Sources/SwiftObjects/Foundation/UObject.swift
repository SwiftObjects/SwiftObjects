//
//  UObject.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Utility functions. Non-Swifty :-)
 */
public enum UObject {
  
  public static func getSimpleName<T>(_ value: T) -> String {
    return String(describing: type(of: value))
  }
  
  public static func boolValue(_ v: Any?) -> Bool {
    guard let v = v else { return false }
    
    if let vv = v as? UObjectBoolValue {
      return vv.swiftObjectsBoolValue
    }

    // TODO: collections etc etc, this is really unswifty in the first place
    //       and should be approached differently ;-)
    return true
  }
  
  public static func boolValue(_ v: String?) -> Bool {
    guard let v = v else { return false }
    
    switch v {
      case "", "0", " ", "NO", "false", "undefined":
        return false
      default:
        return true
    }
  }
  
  public static func stringValue(_ v: Any?) -> String {
    guard let v = v else { return "<nil>" }
    if let s = v as? String { return s }
    if let b = v as? Bool   { return b ? "true" : "false" }
    return String(describing: v)
  }

  public static func intValue(_ v: Any?) -> Int {
    guard let v = v else { return 0 }
    
    if let v = v as? Int    { return v }
    if let v = v as? Bool   { return v ? 1 : 0   }
    if let s = v as? String { return intValue(s) }
    
    // TODO: collections etc etc, this is really unswifty in the first place
    //       and should be approached differently ;-)
    
    return intValue(String(describing: v))
  }
  
  public static func intValue(_ v: String?) -> Int {
    guard let v = v else { return 0 }
    return Int(v) ?? 0
  }
  
  public static func isEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
    // oh man, no proper equal in Swift :-) BAD BAD BAD BAD BAD BAD
    // TODO: in ZeeQL we at least have a protocol for this
    if lhs == nil && rhs == nil { return true  }
    if lhs != nil || rhs != nil { return false }
    guard let lhs = lhs, let rhs = rhs else { return false }
    
    if let lhs = lhs as? Int, let rhs = rhs as? Int {
      return lhs == rhs
    }
    else if let lhs = lhs as? String, let rhs = rhs as? String {
      return lhs == rhs
    }

    if type(of: lhs) != type(of: rhs) { return false }
    
    // This is so so bad I'm feeling sick typing this
    let lhss = UObject.stringValue(lhs)
    let rhss = UObject.stringValue(rhs)
    return lhss == rhss
  }
}

protocol UObjectBoolValue {
  var swiftObjectsBoolValue : Bool { get }
}

extension Bool : UObjectBoolValue {
  var swiftObjectsBoolValue : Bool { return self }
}
extension Int : UObjectBoolValue {
  var swiftObjectsBoolValue : Bool { return self != 0 }
}
extension String : UObjectBoolValue {
  var swiftObjectsBoolValue : Bool { return UObject.boolValue(self) }
}

extension Array : UObjectBoolValue {
  var swiftObjectsBoolValue : Bool { return !isEmpty }
}
extension Set : UObjectBoolValue {
  var swiftObjectsBoolValue : Bool { return !isEmpty }
}

extension Optional : UObjectBoolValue {
  // TODO: conditional conformance etc
  var swiftObjectsBoolValue : Bool {
    switch self {
      case .none: return false
      case .some(let v): return UObject.boolValue(v)
    }
  }
}
