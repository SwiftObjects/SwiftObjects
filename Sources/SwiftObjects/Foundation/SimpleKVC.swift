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
 * Both classes and structs can conform:
 * - Classes implement without the `mutating` keyword
 * - Structs implement with `mutating`
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
   * Returns true if property was found and set, false otherwise.
   * Custom implementations can call this after handling their special cases.
   */
  @discardableResult
  mutating func defaultTakeValueForKey(_ value: Any?, forKey k: String) -> Bool {
    let ti = typeInfo(of: self)
    guard ti.kind == .class || ti.kind == .struct,
          let prop = ti.property(named: k)
    else { return false }
    prop.setValue(value, on: &self)
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
  func defaultTakeValueForKey(_ value: Any?, forKey k: String) -> Bool {
    let ti = typeInfo(of: self)
    guard ti.kind == .class, let prop = ti.property(named: k) else {
      return false
    }
    if let value = value {
      prop.setOnClass(value: value, object: self)
    }
    else {
      prop.setOnClass(value: value as Any, object: self)
    }
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

    let firstKey = p[0]
    let remainingPath = Array(p.dropFirst())

    // Get intermediate value
    guard var intermediate = value(forKey: firstKey, inObject: o) else { return }

    // Check if intermediate is a class (reference type) - if so, just recurse
    let ti = typeInfo(of: type(of: intermediate))
    if ti.kind == .class {
      try takeValue(v, forKeyPath: remainingPath, inObject: intermediate)
      return
    }

    // For value types (structs), we need to bubble changes back
    try takeValueInAny(&intermediate, value: v, forKeyPath: remainingPath)

    // Bubble up - set modified intermediate back on o
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

  public static func takeValue(_ v: Any?, forKey k: String,
                               inObject o: Any?) throws
  {
    if var kvc = o as? MutableKeyValueCodingType {
      try kvc.takeValue(v, forKey: k)
      return
    }

    if let o = o {
      // Use SwiftRuntime for direct property access
      let ti = typeInfo(of: o)
      guard ti.kind == .class || ti.kind == .struct,
            let prop = ti.property(named: k)
      else {
        throw Error.CannotTakeValueForKey(k)
      }

      // For classes, we can set directly
      if ti.kind == .class {
        if let value = v {
          prop.setOnClass(value: coerce(value, to: prop.type), object: o)
        }
        else {
          prop.setOnClass(value: v as Any, object: o)
        }
      }
      else {
        throw Error.CannotTakeValueForKey(k)
      }
    }
  }

  // MARK: - Mutable Struct Operations (inout)

  /**
   * Set a value for a single key on a struct using `inout`.
   * This allows mutation of value types through KVC.
   */
  public static func takeValue<T>(_ v: Any?, forKey k: String,
                                  inObject o: inout T) throws
  {
    // Check if the type implements MutableKeyValueCodingType
    if var kvc = o as? MutableKeyValueCodingType {
      try kvc.takeValue(v, forKey: k)
      if let result = kvc as? T { o = result }
      return
    }

    // Use typeInfo for direct property access
    let ti = typeInfo(of: T.self)
    guard ti.kind == .struct || ti.kind == .class,
          let prop = ti.property(named: k)
    else {
      throw Error.CannotTakeValueForKey(k)
    }

    if let value = v {
      prop.setValue(coerce(value, to: prop.type), on: &o)
    }
    else {
      prop.set(value: v as Any, on: &o)
    }
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

    let firstKey = p[0]
    let remainingPath = Array(p.dropFirst())

    // Get intermediate value
    guard var intermediate = value(forKey: firstKey, inObject: o) else { return }

    // Recurse - modify intermediate (handles both struct and class)
    try takeValueInAny(&intermediate, value: v, forKeyPath: remainingPath)

    // Bubble up - set modified intermediate back
    try takeValue(intermediate, forKey: firstKey, inObject: &o)
  }

  /**
   * Helper to handle `Any` boxing for intermediate values in keypath mutation.
   * This is needed because we don't know the concrete type of intermediate
   * values at compile time.
   */
  private static func takeValueInAny(_ o: inout Any, value v: Any?,
                                     forKeyPath path: [ String ]) throws
  {
    guard !path.isEmpty else { throw Error.EmptyKeyPath }

    // Check if the value conforms to both KVC protocols
    // This provides a safe way to mutate struct values
    if var kvc = o as? MutableKeyValueCodingType,
       let readable = o as? KeyValueCodingType
    {
      if path.count == 1 {
        try kvc.takeValue(v, forKey: path[0])
      }
      else {
        // Get intermediate, recurse, set back
        let firstKey = path[0]
        guard var intermediate = readable.value(forKey: firstKey) else { return }
        try takeValueInAny(&intermediate, value: v,
                           forKeyPath: Array(path.dropFirst()))
        try kvc.takeValue(intermediate, forKey: firstKey)
      }
      o = kvc
      return
    }

    let ti = typeInfo(of: type(of: o))

    // For classes, we can set directly (reference semantics)
    if ti.kind == .class {
      try takeValue(v, forKeyPath: path, inObject: o)
      return
    }

    // For structs without MutableValueKeyValueCodingType conformance,
    // we can only handle single-key paths safely
    guard ti.kind == .struct else {
      throw Error.CannotTakeValueForKey(path.first ?? "")
    }

    if path.count == 1 {
      try setPropertyOnBoxedStruct(&o, value: v, forKey: path[0], typeInfo: ti)
      return
    }

    // For nested paths on plain structs, the intermediate values need to
    // conform to MutableValueKeyValueCodingType. Attempt raw memory access
    // but this may not work reliably for all cases.
    let firstKey = path[0]
    let remainingPath = Array(path.dropFirst())

    guard ti.property(named: firstKey) != nil else {
      throw Error.CannotTakeValueForKey(firstKey)
    }

    // Get intermediate value
    guard var intermediate = value(forKey: firstKey, inObject: o) else { return }

    // Recurse on the intermediate
    try takeValueInAny(&intermediate, value: v, forKeyPath: remainingPath)

    // Set the modified intermediate back on o
    try setPropertyOnBoxedStruct(&o, value: intermediate, forKey: firstKey,
                                 typeInfo: ti)
  }

  /**
   * Helper to set a value for a single key on an Any-boxed value.
   */
  private static func takeValueOnAny(_ o: inout Any, value v: Any?,
                                     forKey k: String) throws
  {
    let ti = typeInfo(of: type(of: o))

    // For classes, we can set directly (reference semantics)
    if ti.kind == .class {
      try takeValue(v, forKey: k, inObject: o)
      return
    }

    // For structs, modify the boxed value in place
    guard ti.kind == .struct else {
      throw Error.CannotTakeValueForKey(k)
    }

    try setPropertyOnBoxedStruct(&o, value: v, forKey: k, typeInfo: ti)
  }

  /**
   * Set a property on a struct that's boxed inside an Any container.
   * This uses unsafe memory access to modify the struct in place.
   *
   * Note: This works for structs ≤24 bytes (stored inline in the Any).
   * Larger structs require additional handling (heap-allocated storage).
   */
  private static func setPropertyOnBoxedStruct(_ o: inout Any, value v: Any?,
                                               forKey k: String,
                                               typeInfo ti: TypeInfo) throws
  {
    guard let prop = ti.property(named: k) else {
      throw Error.CannotTakeValueForKey(k)
    }

    // Use withUnsafeMutableBytes to access the raw bytes of the Any container
    // For inline structs (≤24 bytes), the value starts at the beginning
    // This mirrors how Property.get uses withUnsafeBytes for reading
    withUnsafeMutableBytes(of: &o) { buffer in
      guard let baseAddress = buffer.baseAddress else { return }
      let propPtr = baseAddress.advanced(by: prop.offset)
      if let value = v {
        prop.accessor.set(value: coerce(value, to: prop.type),
                          to: propPtr)
      }
      else {
        prop.accessor.set(value: v as Any, to: propPtr)
      }
    }
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

  private static func coerce(_ value: Any, to type: Any.Type) -> Any {
    if Swift.type(of: value) == type { return value }

    // Basic coercions
    if type == String.self || type == Optional<String>.self {
      if let s = value as? String { return s }
      return String(describing: value)
    }
    if type == Int.self || type == Optional<Int>.self {
      if let i = value as? Int { return i }
      if let s = value as? String { return Int(s) ?? 0 }
      return 0
    }
    if type == Bool.self || type == Optional<Bool>.self {
      return UObject.boolValue(value)
    }

    return value
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
        // For structs: value is inline in the existential container (≤24 bytes)
        // or heap-boxed (>24 bytes). Use withUnsafeBytes for inline access.
        return withUnsafeBytes(of: object) { buffer in
          guard let baseAddress = buffer.baseAddress else { return nil }
          let rawValue = accessor.get(from: baseAddress.advanced(by: offset))
          return unwrapOptional(rawValue)
        }
      }
    }

    func setOnClass(value: Any?, object: Any) {
      // Skip weak references - they have special storage we can't write
      guard isStrong else { return }

      let kind = Kind.of(Swift.type(of: object))
      guard kind == .class else { return }

      // Use Unmanaged to correctly extract class pointer from Any.
      let anyObj = object as AnyObject
      let instancePtr = Unmanaged.passUnretained(anyObj).toOpaque()
      accessor.set(
        value: value as Any,
        to: UnsafeMutableRawPointer(instancePtr).advanced(by: offset)
      )
    }

    func set<T>(value: Any?, on object: inout T) {
      // Skip weak references - they have special storage we can't write
      guard isStrong else { return }

      let kind = Kind.of(T.self)
      guard kind == .class || kind == .struct else { return }

      withUnsafeMutablePointer(to: &object) { ptr in
        if kind == .class {
          ptr.withMemoryRebound(to: UnsafeMutableRawPointer.self, capacity: 1) {
            accessor.set(value: value as Any,
                         to: $0.pointee.advanced(by: offset))
          }
        }
        else {
          accessor.set(value: value as Any,
                       to: UnsafeMutableRawPointer(ptr).advanced(by: offset))
        }
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

fileprivate extension TypeInfo.Property {

  /**
   * Set value with type coercion.
   */
  func setValue<TObject>(_ value: Any?, on object: inout TObject) {
    if let value = value {
      if Swift.type(of: value) == self.type {
        set(value: value, on: &object)
      }
      else if let coercedValue = coerce(value: value, to: self.type) {
        set(value: coercedValue, on: &object)
      }
    }
    else {
      set(value: value as Any, on: &object)
    }
  }

  private func coerce(value: Any, to type: Any.Type) -> Any? {
    if let ct = type as? RuntimeCoercion.Type {
      return try? ct.coerce(runtimeValue: value)
    }
    return nil
  }
}


// MARK: - Accessor Protocol Trick

fileprivate protocol Accessor {}

extension Accessor {

  static func get(from pointer: UnsafeRawPointer) -> Any {
    pointer.assumingMemoryBound(to: Self.self).pointee
  }

  static func set(value: Any, to pointer: UnsafeMutableRawPointer) {
    if let value = value as? Self {
      pointer.assumingMemoryBound(to: Self.self).pointee = value
    }
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
