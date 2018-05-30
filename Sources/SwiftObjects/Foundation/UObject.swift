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

    if let b = v as? Bool { return b }
    if let i = v as? Int  { return i != 0 } // test number

    if let s = v as? String { return boolValue(s) }
    
    // TODO: collections etc etc, this is really unswifty in the first place
    //       and should be approached differently ;-)
    
    return false
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
}
