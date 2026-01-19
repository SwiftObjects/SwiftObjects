//
//  RuntimeCoercion.swift
//  SwiftObjects
//
//  Created by Helge Hess on 30.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

// MARK: - RuntimeCoercion Protocol

protocol RuntimeCoercion {
  
  static func coerce(runtimeValue v: Any?) throws -> Self
  
}

enum CoercionError : Swift.Error {
  case invalidType(got: Any.Type, expected: Any.Type)
}

extension String : RuntimeCoercion {

  static func coerce(runtimeValue v: Any?) throws -> String {
    if      let s = v as? String           { return s }
    else if let s = v as? Optional<String> { return s ?? "" }
    else if let s = v as? Optional<Int>    {
      if let s = s { return String(s) }
      else         { return  "" }
    }
    else if let s = v as? Optional<Bool>    {
      if let s = s { return s ? "true" : "false" }
      else         { return "" }
    }
    else { return String(describing: v) }
  }

}

extension Int : RuntimeCoercion {
  
  static func coerce(runtimeValue v: Any?) throws -> Int {
    if      let s = v as? Int              { return s }
    else if let s = v as? Optional<Int>    { return s ?? 0 }
    else if let s = v as? String           { return Int(s) ?? 0 }
    else if let s = v as? Optional<String> {
      if let s = s { return Int(s) ?? 0 }
      else         { return 0 }
    }
    else if let s = v as? Bool             { return s ? 1 : 0 }
    else if let s = v as? Optional<Bool>   { return (s ?? false) ? 1 : 0 }
    else { return 0 } // TBD: throw?
  }
  
}

extension Bool : RuntimeCoercion {
  
  static func coerce(runtimeValue v: Any?) throws -> Bool {
    return UObject.boolValue(v)
  }
}

extension Optional : RuntimeCoercion {
  
  static func coerce(runtimeValue v: Any?) throws -> Optional<Wrapped> {
    guard let v = v else { return Optional<Wrapped>.none }
    
    if let wv = v as? Wrapped {
      return Optional.some(wv)
    }
    
    // TODO: on 4.1 do Conditional Conformance?
    switch self {
      case is Optional<String>.Type:
        return coerceToOptionalString(value: v) as! Optional<Wrapped>
      
      case is Optional<Int>.Type:
        return coerceToOptionalInt(value: v) as! Optional<Wrapped>
      
      case is Optional<Bool>.Type:
        return (UObject.boolValue(v) as Bool?) as! Optional<Wrapped>
      
      default:
        throw CoercionError.invalidType(got: Swift.type(of: v), expected: self)
    }

  }

  static func coerceToOptionalString(value: Any?) -> String? {
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
  
  static func coerceToOptionalInt(value: Any?) -> Int? {
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

}
