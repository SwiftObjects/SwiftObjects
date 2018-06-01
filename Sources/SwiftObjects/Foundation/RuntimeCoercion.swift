//
//  RuntimeCoercion.swift
//  SwiftObjects
//
//  Created by Helge Hess on 30.05.18.
//

import Foundation
import Runtime

fileprivate protocol OptionalProtocol {
  func isSome() -> Bool
  func unwrap() -> Any
}

extension Optional : OptionalProtocol {
  func isSome() -> Bool {
    switch self {
      case .none: return false
      case .some: return true
    }
  }
  func unwrap() -> Any {
    switch self {
      case .none: preconditionFailure("trying to unwrap nil")
      case .some(let unwrapped): return unwrapped
    }
  }
}

extension Runtime.PropertyInfo {

  public func zget(from object: Any) throws -> Any? {
    /*
       1> let s : String? = "Hello"
       s: String? = "Hello"
       2> let a : Any = s
       a: Any = { .. }
       3> let o = a as Any?
       o: Any? = some { .. }
       4> print("o: \(o)")
       o: Optional(Optional("Hello"))
    */
    // There MUST be a way to do this simpler :-)
    let v = try get(from: object)
    guard let ov = v as? OptionalProtocol else { return v }
    guard ov.isSome() else { return nil }
    return ov.unwrap()
  }

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
      return try ct.coerce(runtimeValue: value)
    }
    
    throw CoercionError.invalidType(got: Swift.type(of: value),
                                    expected: type)
  }
  
  func coerceToString(value: Any?) -> String {
    if let s = value as? String           { return s }
    if let s = value as? Optional<String> { return s ?? "" }
    return String(describing: value)
  }
  enum CoercionError : Swift.Error {
    case invalidType(got: Any.Type, expected: Any.Type)
  }
}

protocol RuntimeCoercion {
  
  static func coerce(runtimeValue v: Any?) throws -> Self
  
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
        throw Runtime.PropertyInfo
                .CoercionError.invalidType(got: Swift.type(of: v),
                                           expected: self)
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
