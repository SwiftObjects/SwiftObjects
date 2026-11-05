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
  
  /**
   * Coerces to an `Int`. `nil` and the empty string (empty form fields) map
   * to 0, non-numeric strings and unsupported types throw.
   */
  static func coerce(runtimeValue v: Any?) throws -> Int {
    if      let s = v as? Int              { return s }
    else if let s = v as? Optional<Int>    { return s ?? 0 }
    else if let s = v as? String           { return try parse(s) }
    else if let s = v as? Optional<String> { return try s.map(parse) ?? 0 }
    else if let s = v as? Bool             { return s ? 1 : 0 }
    else if let s = v as? Optional<Bool>   { return (s ?? false) ? 1 : 0 }
    else if let s = v as? Double           { return Int(s) }
    else if let s = v as? Float            { return Int(s) }
    else {
      throw CoercionError.invalidType(got: type(of: v as Any),
                                      expected: Int.self)
    }
  }
  
  private static func parse(_ s: String) throws -> Int {
    if s.isEmpty { return 0 }
    guard let i = Int(s) else {
      throw CoercionError.invalidType(got: String.self, expected: Int.self)
    }
    return i
  }
}

extension Double : RuntimeCoercion {
  
  /**
   * Coerces to a `Double`. `nil` and the empty string (empty form fields)
   * map to 0, non-numeric strings and unsupported types throw.
   */
  static func coerce(runtimeValue v: Any?) throws -> Double {
    if      let s = v as? Double            { return s }
    else if let s = v as? Optional<Double>  { return s ?? 0 }
    else if let s = v as? Float             { return Double(s) }
    else if let s = v as? Int               { return Double(s) }
    else if let s = v as? String            { return try parse(s) }
    else if let s = v as? Optional<String>  { return try s.map(parse) ?? 0 }
    else if let s = v as? Bool              { return s ? 1 : 0 }
    else {
      throw CoercionError.invalidType(got: type(of: v as Any),
                                      expected: Double.self)
    }
  }
  
  private static func parse(_ s: String) throws -> Double {
    if s.isEmpty { return 0 }
    guard let d = Double(s) else {
      throw CoercionError.invalidType(got: String.self, expected: Double.self)
    }
    return d
  }
}

extension Float : RuntimeCoercion {
  
  static func coerce(runtimeValue v: Any?) throws -> Float {
    if let s = v as? Float { return s }
    return Float(try Double.coerce(runtimeValue: v))
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
      
      case is Optional<Double>.Type:
        return coerceToOptionalDouble(value: v) as! Optional<Wrapped>
      
      case is Optional<Float>.Type:
        return coerceToOptionalDouble(value: v).map(Float.init)
               as! Optional<Wrapped>
      
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
  
  /// Like ``coerceToOptionalInt``, unparsable strings yield nil.
  static func coerceToOptionalDouble(value: Any?) -> Double? {
    if let s = value as? Double           { return s }
    if let s = value as? Optional<Double> { return s }
    if let s = value as? Float            { return Double(s) }
    if let s = value as? Int              { return Double(s) }
    if let s = value as? String           { return Double(s) }
    if let s = value as? Optional<String> { return s.flatMap(Double.init) }
    if let s = value as? Bool             { return s ? 1 : 0 }
    return nil
  }

}
