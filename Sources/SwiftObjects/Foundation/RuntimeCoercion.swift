//
//  RuntimeCoercion.swift
//  SwiftObjects
//
//  Created by Helge Hess on 30.05.18.
//

import Foundation
import Runtime

extension Runtime.PropertyInfo {

  /// Do type coercion
  public func zset<TObject>(value: Any, on object: inout TObject) throws {
    if Swift.type(of: value) == self.type {
      return try set(value: value, on: &object)
    }
    
    let coercedValue = try coerce(value: value, to: self.type)
    assert(Swift.type(of: coercedValue) == self.type)
    return try set(value: coercedValue, on: &object)
  }
  
  func coerce(value: Any, to type: Any.Type) throws -> Any {
    // Again, pretty lame ;-) Suggestions are welcome! @helje5
    
    // Note: Optionals are a little lame here due to 4.0 support
    
    if let ct = type as? RuntimeCoercion.Type {
      return try ct.init(runtimeValue: value)
    }
    
    switch type {
      
      case is Optional<String>.Type:
        return coerceToOptionalString(value: value) as Any

      case is Optional<Int>.Type:
        return coerceToOptionalInt(value: value) as Any
      
      case is Optional<Bool>.Type:
        return (UObject.boolValue(value) as Bool?) as Any

      default:
       throw CoercionError.invalidType(got: Swift.type(of: value),
                                       expected: type)
    }
  }
  
  func coerceToString(value: Any?) -> String {
    if let s = value as? String           { return s }
    if let s = value as? Optional<String> { return s ?? "" }
    return String(describing: value)
  }

  func coerceToOptionalString(value: Any?) -> String? {
    if let s = value as? String           { return s }
    if let s = value as? Optional<String> { return s }
    if let s = value as? Optional<Int>    {
      guard let s = s else { return nil }
      return String(s)
    }
    if let s = value as? Optional<Bool>   {
      guard let s = s else { return nil }
      return s ? "true" : "false"
    }
    return String(describing: value)
  }
  
  func coerceToOptionalInt(value: Any?) -> Int? {
    if let s = value as? Int              { return s }
    if let s = value as? Optional<Int>    { return s }
    if let s = value as? String           { return Int(s) }
    if let s = value as? Optional<String> {
      guard let s = s else { return nil }
      return Int(s)
    }
    if let s = value as? Bool              { return s ? 1 : 0 }
    if let s = value as? Optional<Bool>    {
      guard let s = s else { return nil }
      return s ? 1 : 0
    }
    return nil // TBD: throw?
  }

  enum CoercionError : Swift.Error {
    case invalidType(got: Any.Type, expected: Any.Type)
  }
}

protocol RuntimeCoercion {
  
  init(runtimeValue v: Any?) throws
  
}

extension String : RuntimeCoercion {

  init(runtimeValue v: Any?) throws {
    if      let s = v as? String           { self = s }
    else if let s = v as? Optional<String> { self = s ?? "" }
    else if let s = v as? Optional<Int>    {
      if let s = s { self = String(s) }
      else         { self = "" }
    }
    else if let s = v as? Optional<Bool>    {
      if let s = s { self = s ? "true" : "false" }
      else         { self = "" }
    }
    else { self = String(describing: v) }
  }

}

extension Int : RuntimeCoercion {
  
  init(runtimeValue v: Any?) throws {
    if      let s = v as? Int              { self = s }
    else if let s = v as? Optional<Int>    { self = s ?? 0 }
    else if let s = v as? String           { self = Int(s) ?? 0 }
    else if let s = v as? Optional<String> {
      if let s = s { self = Int(s) ?? 0 }
      else         { self = 0 }
    }
    else if let s = v as? Bool             { self = s ? 1 : 0 }
    else if let s = v as? Optional<Bool>   { self = (s ?? false) ? 1 : 0 }
    else { self = 0 } // TBD: throw?
  }
  
}

extension Bool : RuntimeCoercion {
  
  init(runtimeValue v: Any?) throws {
    self = UObject.boolValue(v)
  }
}
