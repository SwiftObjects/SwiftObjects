//
//  SwiftTypeIndex.swift
//  SwiftObjects
//
//  Created by Helge Hess on 02.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

#if canImport(Darwin)
import MachO
#endif
import class Foundation.NSLock

/**
 * A process-global index of the Swift classes in all loaded images, keyed by
 * their simple, unqualified name (e.g. `Main`).
 *
 * The index is built lazily from the `swift5_types` sections the compiler
 * emits for every nominal type. Those sections are walked directly, via dyld
 * on Darwin and via `swift_enumerateAllMetadataSections` on other platforms.
 * No registration and no knowledge of the module a class lives in is
 * required, which allows ``WODevResourceManager`` to resolve component,
 * direct action, session or context classes by their bare name.
 *
 * Only non-generic classes nested in modules or other nominal types are
 * indexed. Private classes (which live in anonymous contexts) and classes
 * declared inside extensions are skipped, they can't be addressed by a plain
 * name anyway.
 *
 * Building the index does not instantiate any type metadata. Each ``Entry``
 * only records the mangled name of the class, the class object itself is
 * materialized on demand by ``Entry/resolve()``, using the runtime's regular
 * `_typeByName` lookup.
 *
 * The index is built on first use and cached. On Darwin it is rebuilt when
 * the number of loaded images changes (e.g. after a `dlopen`), on other
 * platforms call ``reset()`` after loading additional images.
 */
public enum SwiftTypeIndex {
  
  /// A class found in one of the loaded images.
  public struct Entry : Hashable, Sendable, CustomStringConvertible {
    
    /// The simple name of the class, e.g. `Main`.
    public let name        : String
    
    /// The name of the module the class is defined in, e.g. `WOShowcaseApp`.
    public let module      : String
    
    /**
     * The names of the types enclosing the class, outermost first, with the
     * class name itself as the last element. E.g. `[ "Outer", "Inner" ]` for
     * a class `Inner` nested in `Outer`.
     */
    public let typePath    : [ String ]
    
    /// The mangled name of the class, e.g. `13WOShowcaseApp4MainC`.
    public let mangledName : String
    
    /// The qualified name of the class, e.g. `WOShowcaseApp.Main`.
    public var qualifiedName : String {
      return ([ module ] + typePath).joined(separator: ".")
    }
    
    /// Instantiates the metadata of the class and returns the class object.
    public func resolve() -> AnyClass? {
      return _typeByName(mangledName) as? AnyClass
    }
    
    public var description: String { return "<Class: \(qualifiedName)>" }
  }
  
  private static let lock = NSLock()
  nonisolated(unsafe) private static var index : [ String : [ Entry ] ]? = nil
  nonisolated(unsafe) private static var indexedImageCount = 0
  
  
  // MARK: - API
  
  /**
   * Returns the index entries for all classes with the given simple name,
   * sorted by module and qualified name.
   *
   * - Parameters:
   *   - name: The simple, unqualified name of the class, e.g. `Main`.
   * - Returns: The matching entries, empty if none was found.
   */
  public static func classes(named name: String) -> [ Entry ] {
    lock.lock(); defer { lock.unlock() }
    return currentIndex()[name] ?? []
  }
  
  /**
   * Looks up a class by its simple name. Returns `nil` if no class with that
   * name is loaded, or if the name is ambiguous (i.e. several modules or
   * scopes contain a class with that name).
   *
   * - Parameters:
   *   - name: The simple, unqualified name of the class, e.g. `Main`.
   * - Returns: The class, or nil if it wasn't found or is ambiguous.
   */
  public static func lookupClass(named name: String) -> AnyClass? {
    let entries = classes(named: name)
    guard entries.count == 1, let entry = entries.first else { return nil }
    return entry.resolve()
  }
  
  /// Drops the cached index, it is rebuilt on the next lookup.
  public static func reset() {
    lock.lock(); defer { lock.unlock() }
    index = nil
  }
  
  
  // MARK: - Index Construction
  
  /// Must be called with the lock held.
  private static func currentIndex() -> [ String : [ Entry ] ] {
    #if canImport(Darwin)
      let imageCount = Int(_dyld_image_count())
      if let index, imageCount == indexedImageCount { return index }
    #else
      let imageCount = 0
      if let index { return index }
    #endif
    
    var index = [ String : [ Entry ] ]()
    for section in typeSections() { scan(section, into: &index) }
    for ( name, entries ) in index where entries.count > 1 {
      index[name] = entries.sorted {
        ( $0.module, $0.qualifiedName ) < ( $1.module, $1.qualifiedName )
      }
    }
    
    self.index             = index
    self.indexedImageCount = imageCount
    return index
  }
  
  private static func scan(_ section: UnsafeRawBufferPointer,
                           into index: inout [ String : [ Entry ] ])
  {
    guard let base = section.baseAddress else { return }
    
    // The section is an array of `TypeMetadataRecord`s, 32-bit relative
    // pointers to context descriptors. The two low bits carry the reference
    // kind: 0 = direct, 1 = indirect (points to an absolute pointer).
    for offset in stride(from: 0, to: section.count - 3, by: 4) {
      let record = base + offset
      let value  = Int(record.loadUnaligned(as: Int32.self))
      guard value != 0, value & 3 < 2 else { continue }
      
      var descriptor : UnsafeRawPointer = record + (value & ~3)
      if value & 1 != 0 {
        guard let target = descriptor.loadUnaligned(as: UnsafeRawPointer?.self)
        else { continue }
        descriptor = target
      }
      
      guard let entry = makeEntry(for: descriptor) else { continue }
      index[entry.name, default: []].append(entry)
    }
  }
  
  /// The kind of a context descriptor, stored in the low 5 bits of its flags.
  private enum ContextKind : UInt32 {
    
    case module = 0, `extension` = 1, anonymous = 2, `protocol` = 3
    case opaqueType = 4
    case `class` = 16, `struct` = 17, `enum` = 18
    
    var manglingSuffix : String? {
      switch self {
        case .class:  return "C"
        case .struct: return "V"
        case .enum:   return "O"
        default:      return nil
      }
    }
  }
  
  /**
   * Builds an entry for a class context descriptor, or returns nil if the
   * descriptor does not describe a non-generic class that is reachable by
   * name.
   *
   * Descriptor layout (all fields are 32-bit):
   * - `flags`  (kind in the low 5 bits, bit 7 marks generic contexts)
   * - `parent` (relative indirectable pointer, nullable)
   * - `name`   (relative direct pointer to a C string, type and module
   *            descriptors only)
   */
  private static func makeEntry(for descriptor: UnsafeRawPointer) -> Entry? {
    guard let kind = contextKind(of: descriptor), kind == .class,
          !isGeneric(descriptor), let name = contextName(of: descriptor),
          var mangled = mangle(name, suffix: "C")
    else { return nil }
    
    var typePath = [ name ]
    var current  = descriptor
    
    while let parent = parentContext(of: current) {
      guard let parentKind = contextKind(of: parent) else { return nil }
      
      if parentKind == .module {
        guard let module = contextName(of: parent),
              let prefix = mangle(module, suffix: "")
        else { return nil }
        return Entry(name: name, module: module, typePath: typePath,
                     mangledName: prefix + mangled)
      }
      
      // Nested in another type. Private classes live in anonymous contexts
      // and classes declared in extensions have an extension parent, neither
      // can be referenced by a plain name.
      guard let suffix = parentKind.manglingSuffix, !isGeneric(parent),
            let parentName = contextName(of: parent),
            let prefix = mangle(parentName, suffix: suffix)
      else { return nil }
      
      typePath.insert(parentName, at: 0)
      mangled = prefix + mangled
      current = parent
    }
    return nil // no module parent?!
  }
  
  private static func contextKind(of descriptor: UnsafeRawPointer)
                      -> ContextKind?
  {
    let flags = descriptor.loadUnaligned(as: UInt32.self)
    return ContextKind(rawValue: flags & 0x1F)
  }
  
  private static func isGeneric(_ descriptor: UnsafeRawPointer) -> Bool {
    return descriptor.loadUnaligned(as: UInt32.self) & 0x80 != 0
  }
  
  private static func parentContext(of descriptor: UnsafeRawPointer)
                      -> UnsafeRawPointer?
  {
    let field = descriptor + 4
    let value = Int(field.loadUnaligned(as: Int32.self))
    guard value != 0 else { return nil }
    let target = field + (value & ~1)
    if value & 1 == 0 { return target }
    return target.loadUnaligned(as: UnsafeRawPointer?.self)
  }
  
  private static func contextName(of descriptor: UnsafeRawPointer)
                      -> String?
  {
    let field = descriptor + 8
    let value = Int(field.loadUnaligned(as: Int32.self))
    guard value != 0 else { return nil }
    let cString = (field + value).assumingMemoryBound(to: CChar.self)
    let name = String(cString: cString)
    return name.isEmpty ? nil : name
  }
  
  /**
   * Mangles an identifier as `<length><identifier>` followed by the suffix.
   * Non-ASCII identifiers would require Punycode, those are not supported
   * and yield nil.
   */
  private static func mangle(_ identifier: String, suffix: String)
                      -> String?
  {
    guard identifier.utf8.allSatisfy({ $0 < 128 }) else { return nil }
    return "\(identifier.utf8.count)\(identifier)\(suffix)"
  }
  
  
  // MARK: - Locating the Type Sections
  
#if canImport(Darwin)
  
  /// Returns the `__swift5_types` sections of all images that are not part
  /// of the dyld shared cache (system frameworks never contain app classes).
  private static func typeSections() -> [ UnsafeRawBufferPointer ] {
    #if arch(i386) || arch(arm)
      typealias Header = mach_header
    #else
      typealias Header = mach_header_64
    #endif
    let inSharedCache : UInt32 = 0x8000_0000 // MH_DYLIB_IN_CACHE
    
    var sections = [ UnsafeRawBufferPointer ]()
    for i in 0..<_dyld_image_count() {
      guard let header = _dyld_get_image_header(i) else { continue }
      guard header.pointee.flags & inSharedCache == 0 else { continue }
      
      var size   : UInt = 0
      let header64 = UnsafeRawPointer(header)
                       .assumingMemoryBound(to: Header.self)
      guard let start = getsectiondata(header64, "__TEXT", "__swift5_types",
                                       &size), size > 0
      else { continue }
      sections.append(UnsafeRawBufferPointer(start: start, count: Int(size)))
    }
    return sections
  }
  
#elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
  
  nonisolated(unsafe)
  private static var collectedSections = [ UnsafeRawBufferPointer ]()
  
  /**
   * Returns the `swift5_type_metadata` sections of all images the Swift
   * runtime knows about.
   *
   * The callback receives a `MetadataSections` struct (see the runtime's
   * `MetadataSections.h`), which starts with four pointer-sized words
   * (`version`, `baseAddress`, two unused words), followed by `start` and
   * `length` word pairs for the individual sections. The type metadata range
   * is the third pair.
   */
  private static func typeSections() -> [ UnsafeRawBufferPointer ] {
    collectedSections.removeAll()
    swift_enumerateAllMetadataSections({ sections, _ in
      let word   = MemoryLayout<UInt>.size
      let start  = sections.load(fromByteOffset: 8 * word, as: UInt.self)
      let length = sections.load(fromByteOffset: 9 * word, as: UInt.self)
      guard length > 0, let base = UnsafeRawPointer(bitPattern: start) else {
        return true
      }
      SwiftTypeIndex.collectedSections
        .append(UnsafeRawBufferPointer(start: base, count: Int(length)))
      return true
    }, nil)
    defer { collectedSections.removeAll() }
    return collectedSections
  }
  
#else
  
  private static func typeSections() -> [ UnsafeRawBufferPointer ] {
    return [] // unsupported platform, falls back to module based lookup
  }
  
#endif
}

#if os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
@_silgen_name("swift_enumerateAllMetadataSections")
private func swift_enumerateAllMetadataSections(
  _ body    : @convention(c) ( UnsafeRawPointer, UnsafeMutableRawPointer? )
                              -> Bool,
  _ context : UnsafeMutableRawPointer?
)
#endif
