//
//  EquatableType.swift
//  SwiftObjects
//
//  Based on ZeeQL3's EquatableType.swift
//  Copyright © 2017-2024 ZeeZide GmbH. All rights reserved.
//

import struct Foundation.Date
import struct Foundation.UUID
import struct Foundation.URL
import struct Foundation.Data
import struct Foundation.Decimal

/**
 * Dynamic comparison of values. The thing you know from Objective-C or Java.
 */
public protocol EquatableType {
  func isEqual(to object: Any?) -> Bool
}

// MARK: - Generic eq() Functions

@inlinable
public func eq<T: Equatable>(_ a: T?, _ b: T?) -> Bool {
  if let a = a, let b = b { return a == b }
  return a == nil && b == nil
}

@inlinable
public func eq(_ a: Any?, _ b: Any?) -> Bool {
  if let a = a, let b = b {
    if let a = a as? EquatableType { return a.isEqual(to: b) }
    // Swift 5.5+ fallback to any Equatable
    func _isEqual<T: Equatable>(lhs: T, rhs: Any) -> Bool {
      guard let rhs = rhs as? T else { return false }
      return lhs == rhs
    }
    guard let lhs = a as? any Equatable else { return false }
    return _isEqual(lhs: lhs, rhs: b)
  }
  return a == nil && b == nil
}


// MARK: - FixedWidthInteger

public extension FixedWidthInteger {

  @inlinable
  func isEqual(to object: Any?) -> Bool {
    guard let object else { return false }
    switch object {
      case let other as Int:     return self == other
      case let other as Decimal: return other.isEqual(to: self)
      case let other as Int64:   return self == other
      case let other as Int32:   return self == other
      case let other as Int16:   return self == other
      case let other as Int8:    return self == other
      case let other as UInt:    return self == other
      case let other as UInt64:  return self == other
      case let other as UInt32:  return self == other
      case let other as UInt16:  return self == other
      case let other as UInt8:   return self == other
      default: return false
    }
  }
}

extension Int    : EquatableType {}
extension Int8   : EquatableType {}
extension Int16  : EquatableType {}
extension Int32  : EquatableType {}
extension Int64  : EquatableType {}
extension UInt   : EquatableType {}
extension UInt8  : EquatableType {}
extension UInt16 : EquatableType {}
extension UInt32 : EquatableType {}
extension UInt64 : EquatableType {}


// MARK: - Float / Double

extension Float : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    guard let v = object as? Float else { return false }
    return self == v
  }
}

extension Double : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    guard let v = object as? Double else { return false }
    return self == v
  }
}


// MARK: - String

extension String : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    guard let object else { return false }
    switch object {
      case let other as String:    return self == other
      case let other as Substring: return self == other
      default: return false
    }
  }
}

extension Substring : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    guard let object else { return false }
    switch object {
      case let other as String:    return self == other
      case let other as Substring: return self == other
      default: return false
    }
  }
}


// MARK: - Bool

extension Bool : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    guard let v = object as? Bool else { return false }
    return self == v
  }
}


// MARK: - Foundation Types

extension Date : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    guard let v = object as? Date else { return false }
    return self == v
  }
}

extension UUID : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    guard let v = object as? UUID else { return false }
    return self == v
  }
}

extension URL : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    guard let v = object as? URL else { return false }
    return self == v
  }
}

extension Data : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    guard let v = object as? Data else { return false }
    return self == v
  }
}

extension Decimal : EquatableType {
  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    switch object {
      case let other as Decimal: return self == other
      case let other as Int:     return Decimal(other) == self
      case let other as Int64:   return Decimal(other) == self
      case let other as Int32:   return Decimal(other) == self
      case let other as Int16:   return Decimal(other) == self
      case let other as Int8:    return Decimal(other) == self
      case let other as UInt:    return Decimal(other) == self
      case let other as UInt64:  return Decimal(other) == self
      case let other as UInt32:  return Decimal(other) == self
      case let other as UInt16:  return Decimal(other) == self
      case let other as UInt8:   return Decimal(other) == self
      default: return false
    }
  }
}


// MARK: - Optional

extension Optional : EquatableType {

  @inlinable
  public func isEqual(to object: Any?) -> Bool {
    if let object { // other is non-nil
      switch self {
        case .none: return false
        case .some(let value):
          if let eqv = value as? EquatableType {
            return eqv.isEqual(to: object)
          }
          else if let eqv = object as? EquatableType {
            return eqv.isEqual(to: value)
          }
          return false
      }
    }
    else { // other is nil
      if case .none = self { return true }
      return false
    }
  }
}
