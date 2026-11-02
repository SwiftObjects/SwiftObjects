//
//  SimpleKVC.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

import Synchronization

public protocol KeyValueCodingType {
  
  func value(forKey k: String) -> Any?
  func handleQueryWithUnboundKey(_ key: String) -> Any?
  func values(forKeys keys: [String]) -> [ String : Any ]

}

/**
 * Protocol for types that support mutable KVC.
 *
 * Both classes and structs can conform, classes implement the requirements
 * without the `mutating` keyword. Note that a struct conformer can only be
 * mutated through the `inout` variants of the ``KeyValueCoding`` functions,
 * the `Any?` based variants throw ``KeyValueCoding/Error`` for value types.
 */
public protocol MutableKeyValueCodingType {

  mutating func takeValue(_ value: Any?, forKey k: String) throws
  mutating func handleTakeValue(_ value: Any?, forUnboundKey k: String) throws
  mutating func takeValuesForKeys(_ values: [ String : Any? ]) throws
}

public extension KeyValueCodingType {

  /**
   * Standard implementation that checks ExtraVariables, does typeInfo lookup,
   * and calls handleQueryWithUnboundKey. Custom implementations can call this
   * after handling their special cases.
   */
  func defaultValueForKey(_ k: String) -> Any? {
    // Check ExtraVariables first
    if let ev = self as? ExtraVariables,
       let v = ev.variableDictionary[k] { return v }

    // Do typeInfo lookup
    let ti = typeInfo(of: self)
    if ti.kind == .class || ti.kind == .struct {
      if let prop = ti.property(named: k) {
        return prop.get(from: self)
      }
    }

    // Not found
    return handleQueryWithUnboundKey(k)
  }

  func value(forKey k: String) -> Any? {
    return defaultValueForKey(k)
  }
  
  func values(forKeys keys: [String]) -> [ String : Any ] {
    var values = [ String : Any ]()
    values.reserveCapacity(keys.count)
    for key in keys {
      guard let value = self.value(forKey: key) else { continue }
      values[key] = value
    }
    return values
  }
  
}

public extension MutableKeyValueCodingType {

  /**
   * Standard implementation using typeInfo for direct property access.
   * Returns true if the property was found and set, false if there is no
   * stored property with that name. Throws if the value can't be coerced to
   * the type of the property. Custom implementations can call this after
   * handling their special cases.
   */
  @discardableResult
  mutating func defaultTakeValueForKey(_ value: Any?, forKey k: String) throws
                -> Bool
  {
    let ti = typeInfo(of: self)
    guard ti.kind == .class || ti.kind == .struct,
          let prop = ti.property(named: k)
    else { return false }
    try prop.set(value, forKey: k, on: &self)
    return true
  }

  mutating func handleTakeValue(_ value: Any?, forUnboundKey k: String) throws {
    throw KeyValueCoding.Error.CannotTakeValueForKey(k)
  }

  mutating func takeValuesForKeys(_ values: [ String : Any? ]) throws {
    for ( key, value ) in values {
      try takeValue(value, forKey: key)
    }
  }
}

/// Non-mutating overloads for classes (reference types).
public extension MutableKeyValueCodingType where Self: AnyObject {

  @discardableResult
  func defaultTakeValueForKey(_ value: Any?, forKey k: String) throws -> Bool {
    let ti = typeInfo(of: self)
    guard ti.kind == .class, let prop = ti.property(named: k) else {
      return false
    }
    try prop.set(value, forKey: k, onClass: self)
    return true
  }

  func handleTakeValue(_ value: Any?, forUnboundKey k: String) throws {
    throw KeyValueCoding.Error.CannotTakeValueForKey(k)
  }

  func takeValuesForKeys(_ values: [ String : Any? ]) throws {
    for ( key, value ) in values {
      try KeyValueCoding.takeValue(value, forKey: key, inObject: self)
    }
  }
}


// MARK: - KeyValueCoding

public struct KeyValueCoding {
  
  public enum Error : Swift.Error {
    case UnsupportedDictionaryKeyType(Any.Type)
    case CannotCoerceValueForKey(Any.Type, Any?, String)
    case CannotCoerceValue(Any.Type, Any?)
    case EmptyKeyPath
    case CannotTakeValueForKey(String)
    
    /**
     * Thrown when a value type (struct) is passed to one of the `Any?` based
     * `takeValue` functions. Those would only modify a copy, use the `inout`
     * variants for value types.
     */
    case CannotTakeValueOnValueType(Any.Type, String)
  }

  // MARK: - KeyPath Operations

  public static func takeValue(_ v: Any?, forKeyPath p: String,
                               inObject o: Any?) throws
  {
    let path = p.split(separator: ".").map(String.init)
    try takeValue(v, forKeyPath: path, inObject: o)
  }

  public static func takeValue(_ v: Any?, forKeyPath p: [ String ],
                               inObject o: Any?) throws
  {
    guard !p.isEmpty else { throw Error.EmptyKeyPath }
    guard let o = o  else { return } // no-op

    if p.count == 1 { return try takeValue(v, forKey: p[0], inObject: o) }

    let firstKey      = p[0]
    let remainingPath = Array(p.dropFirst())

    guard var intermediate = value(forKey: firstKey, inObject: o) else {
      return
    }

    // Classes have reference semantics, just recurse.
    if typeInfo(of: intermediate).kind == .class {
      try takeValue(v, forKeyPath: remainingPath, inObject: intermediate)
      return
    }

    // Value types are modified in the box and then bubbled back up.
    try takeValue(v, forKeyPath: remainingPath, inBoxed: &intermediate)
    try takeValue(intermediate, forKey: firstKey, inObject: o)
  }

  public static func value(forKeyPath p: String, inObject o: Any?) -> Any? {
    let path = p.split(separator: ".").map(String.init)
    return value(forKeyPath: path, inObject: o)
  }
  
  public static func value(forKeyPath p: [ String ], inObject o: Any?) -> Any? {
    var cursor = o
    for key in p {
      cursor = value(forKey: key, inObject: cursor)
      if cursor == nil { break }
    }
    return cursor
  }

  // MARK: - Single Key Operations

  /**
   * Sets a value for a key on an object. The object must be a class
   * instance, value types can't be modified through this function, use the
   * `inout` variant for those.
   */
  public static func takeValue(_ v: Any?, forKey k: String,
                               inObject o: Any?) throws
  {
    guard let o = o else { return } // no-op
    
    let ti = typeInfo(of: o)
    guard ti.kind == .class else {
      throw Error.CannotTakeValueOnValueType(Swift.type(of: o), k)
    }
    
    if var kvc = o as? MutableKeyValueCodingType {
      try kvc.takeValue(v, forKey: k)
      return
    }

    guard let prop = ti.property(named: k) else {
      throw Error.CannotTakeValueForKey(k)
    }
    try prop.set(v, forKey: k, onClass: o as AnyObject)
  }

  // MARK: - Mutable Struct Operations (inout)

  /**
   * Set a value for a single key on a struct (or class) using `inout`.
   * This allows mutation of value types through KVC.
   *
   * `T` can also be an optional (e.g. `Point?` or `Any?`), in which case the
   * wrapped value is modified and rewrapped. A `nil` optional is a no-op.
   */
  public static func takeValue<T>(_ v: Any?, forKey k: String,
                                  inObject o: inout T) throws
  {
    let ti = typeInfo(of: T.self)
    
    // Unwrap optionals, modify the wrapped value and rewrap it.
    if ti.kind == .optional {
      guard let optional = o as? OptionalUnwrap,
            var boxed = optional.unwrap()
      else { return } // no-op, like the `Any?` variant
      try takeValue(v, forKey: k, inBoxed: &boxed)
      guard let result = boxed as? T else {
        throw Error.CannotCoerceValueForKey(T.self, boxed, k)
      }
      o = result
      return
    }
    
    // `T` is `Any` or some protocol, work on the dynamic type.
    if ti.kind == .existential {
      var boxed : Any = o
      try takeValue(v, forKey: k, inBoxed: &boxed)
      guard let result = boxed as? T else {
        throw Error.CannotCoerceValueForKey(T.self, boxed, k)
      }
      o = result
      return
    }
    
    if var kvc = o as? MutableKeyValueCodingType {
      try kvc.takeValue(v, forKey: k)
      if let result = kvc as? T { o = result }
      return
    }

    guard ti.kind == .struct || ti.kind == .class,
          let prop = ti.property(named: k)
    else {
      throw Error.CannotTakeValueForKey(k)
    }
    try prop.set(v, forKey: k, on: &o)
  }

  /**
   * Set a value for a keypath on a struct using `inout`.
   * This implements bubbling: intermediate values are retrieved, modified,
   * and then set back on the parent.
   */
  public static func takeValue<T>(_ v: Any?, forKeyPath p: String,
                                  inObject o: inout T) throws
  {
    let path = p.split(separator: ".").map(String.init)
    try takeValue(v, forKeyPath: path, inObject: &o)
  }

  /**
   * Set a value for a keypath (as array) on a struct using `inout`.
   */
  public static func takeValue<T>(_ v: Any?, forKeyPath p: [ String ],
                                  inObject o: inout T) throws
  {
    guard !p.isEmpty else { throw Error.EmptyKeyPath }

    if p.count == 1 {
      try takeValue(v, forKey: p[0], inObject: &o)
      return
    }

    let firstKey      = p[0]
    let remainingPath = Array(p.dropFirst())

    guard var intermediate = value(forKey: firstKey, inObject: o) else {
      return
    }
    try takeValue(v, forKeyPath: remainingPath, inBoxed: &intermediate)
    try takeValue(intermediate, forKey: firstKey, inObject: &o)
  }

  // MARK: - Boxed Values

  /**
   * Sets a value for a keypath on a value boxed in an `Any`, writing the
   * modified value back into the box. Classes are modified in place.
   */
  private static func takeValue(_ v: Any?, forKeyPath path: [ String ],
                                inBoxed o: inout Any) throws
  {
    guard let key = path.first else { throw Error.EmptyKeyPath }
    
    if typeInfo(of: o).kind == .class {
      try takeValue(v, forKeyPath: path, inObject: o)
      return
    }
    
    let remainingPath = Array(path.dropFirst())
    if remainingPath.isEmpty {
      try takeValue(v, forKey: key, inBoxed: &o)
      return
    }

    // Nested path into a value type: fetch the intermediate value, modify
    // it, and bubble it back up.
    guard var intermediate = value(forKey: key, inObject: o) else { return }
    try takeValue(v, forKeyPath: remainingPath, inBoxed: &intermediate)
    try takeValue(intermediate, forKey: key, inBoxed: &o)
  }

  /**
   * Sets a value for a single key on a value boxed in an `Any`, writing the
   * modified value back into the box. Classes are modified in place.
   */
  private static func takeValue(_ v: Any?, forKey k: String,
                                inBoxed o: inout Any) throws
  {
    if var kvc = o as? MutableKeyValueCodingType {
      try kvc.takeValue(v, forKey: k)
      o = kvc
      return
    }

    let ti = typeInfo(of: o)
    guard ti.kind == .class || ti.kind == .struct,
          let prop = ti.property(named: k)
    else {
      throw Error.CannotTakeValueForKey(k)
    }
    
    if ti.kind == .class { try prop.set(v, forKey: k, onClass: o as AnyObject) }
    else                 { try prop.set(v, forKey: k, onBoxed: &o) }
  }

  public static func value(forKey k: String, inObject o: Any?) -> Any? {
    if let kvc = o as? KeyValueCodingType {
      return kvc.value(forKey: k)
    }
    return defaultValue(forKey: k, inObject: o)
  }

  // MARK: - Default Value Implementation

  public static func defaultValue(forKey k: String, inObject o: Any?) -> Any? {
    guard let object = o else { return nil }

    // Safety check: detect double-boxed Any (Any containing Any)
    // This can happen when values pass through multiple KVC layers
    let objectType = Swift.type(of: object)
    let typeName = String(reflecting: objectType)
    if typeName == "Any" || typeName == "Swift.AnyObject" {
      return nil
    }

    // Handle optionals by unwrapping
    let ti = typeInfo(of: objectType)
    if ti.kind == .optional {
      guard let opt = object as? OptionalUnwrap,
            let unwrapped = opt.unwrap()
      else { return nil }
      return value(forKey: k, inObject: unwrapped)
    }

    // Handle existential types (Any, AnyObject, protocols) - can't do KVC
    if ti.kind == TypeInfo.Kind.existential {
      return nil
    }

    // Handle dictionaries specially
    if let dict = object as? [ String : Any ] {
      return dict[k]
    }
    if let dict = object as? [ String : Any? ] {
      return dict[k] ?? nil
    }

    // Use SwiftRuntime for struct/class property access
    if ti.kind == .class || ti.kind == .struct {
      if let prop = ti.property(named: k) {
        return prop.get(from: object)
      }
    }

    return nil
  }

  public static func values(forKeys keys: [ String ], inObject o: Any?)
                     -> [ String : Any ]
  {
    guard let o = o else { return [:] }
    
    if let ko = o as? KeyValueCodingType {
      return ko.values(forKeys: keys)
    }
    
    var values = [ String : Any ]()
    for key in keys {
      if let value = value(forKey: key, inObject: o) {
        values[key] = value
      }
    }
    return values
  }

  // MARK: - Type Coercion

  /**
   * Coerces a value to the type of a property. Types conforming to
   * `RuntimeCoercion` (String, Int, Double, Float, Bool and their optionals)
   * are converted, e.g. form strings to numbers. Other values are passed
   * through unchanged, the property accessor then checks whether the value
   * actually matches the property type.
   *
   * - Parameters:
   *   - value: The value to coerce, nil for `nil`.
   *   - type:  The type of the property.
   *   - k:     The key being set, for error reporting.
   * - Throws: `CannotCoerceValueForKey` if the value can't be converted.
   * - Returns: The coerced value, nil is returned as an `Any` holding nil.
   */
  fileprivate static func coerce(_ value: Any?, to type: Any.Type,
                                 forKey k: String) throws -> Any
  {
    if let value = value, Swift.type(of: value) == type { return value }
    guard let ct = type as? RuntimeCoercion.Type else { return value as Any }
    do {
      return try ct.coerce(runtimeValue: value)
    }
    catch {
      throw Error.CannotCoerceValueForKey(type, value, k)
    }
  }
}


// MARK: - KVC for Swift Base Collections

extension Dictionary: KeyValueCodingType {

  public mutating func takeValue(_ value : Any?, forKey key: String) throws {
    guard let k = key as? Key else {
      throw KeyValueCoding.Error.UnsupportedDictionaryKeyType(Key.self)
    }

    guard let v = value as? Value else {
      throw KeyValueCoding.Error.CannotCoerceValueForKey(Value.self, value, key)
    }
    
    self[k] = v
  }
  
  public func value(forKey k: String) -> Any? {
    if let k = k as? Key {
      guard let value : Value = self[k] else { return nil }
      return value
    }
    
    if Key.self is Int.Type {
      guard let ik = Int(k) else { return nil }
      guard let value : Value = self[ik as! Key] else { return nil }
      return value
    }

    return nil
  }
  
}

extension Array : KeyValueCodingType {

  public func value(forKey k: String) -> Any? {
    // Element
    if k.hasPrefix("@") {
      switch k {
        case "@count": return count
        // TODO: @avg etc
        default: break
      }
    }
    
    guard !isEmpty else { return [] }

    return map { KeyValueCoding.defaultValue(forKey: k, inObject: $0) }
  }
}


public extension KeyValueCodingType {
  func handleQueryWithUnboundKey(_ key: String) -> Any? {
    return nil
  }
}


// MARK: - Swift Runtime Type Metadata
// Inspired by ikhvorost/KeyValueCoding.

/**
 * Cached metadata for a Swift type including its properties.
 * Private to this file - external code should use KeyValueCoding API.
 */
fileprivate struct TypeInfo {

  enum Kind : UInt {

    case `class`      = 0
    case `struct`     = 0x200
    case `enum`       = 0x201
    case optional     = 0x202
    case tuple        = 0x301
    case function     = 0x302
    case existential  = 0x303  // Any, AnyObject, protocol types
    case metatype     = 0x304
    case other        = 0xffff

    static func of(_ type: Any.Type) -> Self {
      let raw = swift_getMetadataKind(type)
      if let kind = Self(rawValue: raw) { return kind }
      // Existential types have various kind values in 0x300 range
      if raw >= 0x300 && raw < 0x400 { return .existential }
      return .other
    }
  }

  struct Property {

    let name     : String
    let type     : Any.Type
    let isStrong : Bool  // false for weak references
    let offset   : Int
    let accessor : Accessor.Type

    func get(from object: Any) -> Any? {
      // Skip weak references - they have special storage we can't read
      guard isStrong else { return nil }

      let objectType = Swift.type(of: object)
      let kind = Kind.of(objectType)
      guard kind == .class || kind == .struct else { return nil }

      if kind == .class {
        // For classes: cast to AnyObject and use Unmanaged to get raw pointer.
        let anyObj = object as AnyObject
        let instancePtr = Unmanaged.passUnretained(anyObj).toOpaque()
        let rawValue = accessor.get(
          from: UnsafeRawPointer(instancePtr).advanced(by: offset)
        )
        return unwrapOptional(rawValue)
      }
      else {
        // For structs: the value is either inline in the existential
        // container or heap-boxed, `withValueBytes` opens the existential to
        // get at the actual value either way.
        return withValueBytes(of: object) { base in
          unwrapOptional(accessor.get(from: base.advanced(by: offset)))
        } ?? nil
      }
    }

    /**
     * Sets the property on a class instance. The value is coerced to the
     * property type, a `CannotCoerceValueForKey` error is thrown if that is
     * not possible.
     */
    func set(_ value: Any?, forKey k: String, onClass object: AnyObject)
           throws
    {
      // Skip weak references - they have special storage we can't write
      guard isStrong, Kind.of(Swift.type(of: object)) == .class else {
        throw KeyValueCoding.Error.CannotTakeValueForKey(k)
      }
      
      let coerced = try KeyValueCoding.coerce(value, to: type, forKey: k)
      let instancePtr = Unmanaged.passUnretained(object).toOpaque()
      let ok = accessor.set(value: coerced,
                            to: UnsafeMutableRawPointer(instancePtr)
                                  .advanced(by: offset))
      guard ok else {
        throw KeyValueCoding.Error.CannotCoerceValueForKey(type, value, k)
      }
    }

    /**
     * Sets the property on a struct (or class) passed `inout`. The value is
     * coerced to the property type, a `CannotCoerceValueForKey` error is
     * thrown if that is not possible.
     */
    func set<T>(_ value: Any?, forKey k: String, on object: inout T) throws {
      let kind = Kind.of(T.self)
      if kind == .class {
        return try set(value, forKey: k, onClass: object as AnyObject)
      }
      guard kind == .struct, isStrong else {
        throw KeyValueCoding.Error.CannotTakeValueForKey(k)
      }
      
      let coerced = try KeyValueCoding.coerce(value, to: type, forKey: k)
      let ok = withUnsafeMutablePointer(to: &object) { ptr in
        accessor.set(value: coerced,
                     to: UnsafeMutableRawPointer(ptr).advanced(by: offset))
      }
      guard ok else {
        throw KeyValueCoding.Error.CannotCoerceValueForKey(type, value, k)
      }
    }

    /**
     * Sets the property on a struct boxed in an `Any`, the modified struct
     * is written back into the box.
     */
    func set(_ value: Any?, forKey k: String, onBoxed any: inout Any) throws {
      guard Kind.of(Swift.type(of: any)) == .struct, isStrong else {
        throw KeyValueCoding.Error.CannotTakeValueForKey(k)
      }
      
      let coerced = try KeyValueCoding.coerce(value, to: type, forKey: k)
      let ok = withMutableValueBytes(of: &any) { base in
        accessor.set(value: coerced, to: base.advanced(by: offset))
      } ?? false
      guard ok else {
        throw KeyValueCoding.Error.CannotCoerceValueForKey(type, value, k)
      }
    }

    private func unwrapOptional(_ value: Any) -> Any? {
      guard let optional = value as? OptionalUnwrap else { return value }
      // Check isSome() first to avoid crash on invalid memory
      guard optional.isSome() else { return nil }
      return optional.unwrap()
    }
  }

  let kind       : Kind
  let properties : [ Property ]

  fileprivate init(of type: Any.Type) {
    self.kind = Kind.of(type)

    if kind == .class || kind == .struct {
      let count = swift_reflectionMirror_recursiveCount(type)
      var props = [ Property ]()
      props.reserveCapacity(count)

      for i in 0..<count {
        var fieldMeta = FieldReflectionMetadata()
        let propType  = swift_reflectionMirror_recursiveChildMetadata(
          type, index: i, fieldMetadata: &fieldMeta
        )
        defer { fieldMeta.freeFunc?(fieldMeta.name) }

        var name = fieldMeta.name.map { String(cString: $0) } ?? ""

        // Handle lazy storage
        let lazyPrefix = "$__lazy_storage_$_"
        if name.hasPrefix(lazyPrefix) {
          name = String(name.dropFirst(lazyPrefix.count))
        }

        let offset = swift_reflectionMirror_recursiveChildOffset(type, index: i)
        let propContainer = ProtocolTypeContainer(type: propType)

        props.append(Property(
          name: name, type: propType, isStrong: fieldMeta.isStrong,
          offset: offset, accessor: propContainer.accessor
        ))
      }
      self.properties = props
    }
    else {
      self.properties = []
    }
  }

  /**
   * Find a property by name.
   */
  func property(named name: String) -> Property? {
    properties.first { $0.name == name }
  }
}

// MARK: - Existential Access

/**
 * Runs `body` with a pointer to the bytes of the value stored in `any`.
 *
 * The value may be stored inline in the existential container or in a heap
 * box, so the bytes of the `Any` itself can't be used. This opens the
 * existential to get a properly typed copy of the value and passes a pointer
 * to that.
 */
fileprivate func withValueBytes<R>(of any: Any,
                                   _ body: (UnsafeRawPointer) -> R) -> R?
{
  func open<T>(_: T.Type) -> R? {
    guard let value = any as? T else { return nil }
    return withUnsafeBytes(of: value) { $0.baseAddress.map(body) }
  }
  return _openExistential(type(of: any), do: open)
}

/**
 * Runs `body` with a mutable pointer to a typed copy of the value stored in
 * `any`, and writes the copy back into `any` afterwards. See
 * ``withValueBytes(of:_:)``.
 */
fileprivate func withMutableValueBytes<R>(of any: inout Any,
                                          _ body: (UnsafeMutableRawPointer)
                                                  -> R) -> R?
{
  func open<T>(_: T.Type) -> R? {
    guard var value = any as? T else { return nil }
    let result = withUnsafeMutableBytes(of: &value) {
      $0.baseAddress.map(body)
    }
    any = value
    return result
  }
  return _openExistential(type(of: any), do: open)
}


// MARK: - Accessor Protocol Trick

fileprivate protocol Accessor {}

extension Accessor {

  static func get(from pointer: UnsafeRawPointer) -> Any {
    pointer.assumingMemoryBound(to: Self.self).pointee
  }

  /// Returns false if the value does not match the property type.
  static func set(value: Any, to pointer: UnsafeMutableRawPointer) -> Bool {
    guard let value = value as? Self else { return false }
    pointer.assumingMemoryBound(to: Self.self).pointee = value
    return true
  }
}

fileprivate struct ProtocolTypeContainer {

  let type: Any.Type
  let witnessTable = 0

  var accessor: Accessor.Type {
    unsafeBitCast(self, to: Accessor.Type.self)
  }
}


// MARK: - Optional Unwrapping (without Mirror)

fileprivate protocol OptionalUnwrap {
  func isSome() -> Bool
  func unwrap() -> Any?
}

extension Optional : OptionalUnwrap {

  func isSome() -> Bool {
    switch self {
      case .none: return false
      case .some: return true
    }
  }

  func unwrap() -> Any? {
    switch self {
      case .none:                return nil
      case .some(let unwrapped): return unwrapped
    }
  }
}


// MARK: - TypeInfo Cache

private let typeInfoCache = Mutex<[ ObjectIdentifier : TypeInfo ]>([:])

/**
 * Get cached TypeInfo for a type.
 * Private to this file - external code should use KeyValueCoding API.
 */
fileprivate func typeInfo(of type: Any.Type) -> TypeInfo {
  let key = ObjectIdentifier(type)
  return typeInfoCache.withLock { cache in
    if let cached = cache[key] { return cached }
    let info = TypeInfo(of: type)
    cache[key] = info
    return info
  }
}

/**
 * Get cached TypeInfo for a value's type.
 * Private to this file - external code should use KeyValueCoding API.
 */
fileprivate func typeInfo<T>(of value: T) -> TypeInfo {
  typeInfo(of: Swift.type(of: value as Any))
}


// MARK: - Swift Runtime Bindings

fileprivate typealias NameFreeFunc =
  @convention(c) (UnsafePointer<CChar>?) -> Void

fileprivate struct FieldReflectionMetadata {

  let name: UnsafePointer<CChar>? = nil
  let freeFunc: NameFreeFunc?     = nil
  let isStrong: Bool              = false
  let isVar: Bool                 = false
}

@_silgen_name("swift_reflectionMirror_recursiveCount")
fileprivate func swift_reflectionMirror_recursiveCount(_: Any.Type) -> Int

@_silgen_name("swift_reflectionMirror_recursiveChildMetadata")
fileprivate func swift_reflectionMirror_recursiveChildMetadata(
  _: Any.Type, index: Int,
  fieldMetadata: UnsafeMutablePointer<FieldReflectionMetadata>
) -> Any.Type

@_silgen_name("swift_reflectionMirror_recursiveChildOffset")
fileprivate func swift_reflectionMirror_recursiveChildOffset(
  _: Any.Type, index: Int
) -> Int

@_silgen_name("swift_getMetadataKind")
fileprivate func swift_getMetadataKind(_: Any.Type) -> UInt
