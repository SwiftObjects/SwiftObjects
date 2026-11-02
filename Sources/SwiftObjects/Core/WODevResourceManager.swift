//
//  WOSourceTreeResourceManager.swift
//  SwiftObjects
//
//  Created by Helge Hess on 20.05.18.
//

import class Foundation.FileManager
import struct Foundation.URL
import struct Foundation.Data

/**
 * A basic resource manager, which looks up classes by name and resources
 * relative to some source file (using the #filePath trick).
 */
open class WODevResourceManager : WOResourceManagerBase {
  
  public struct InMemoryResource {
    let name        : String
    let contentType : String?
    let content     : Data
    let isGZipped   : Bool
    
    public init(_ name: String, _ content: Data,
                contentType: String? = nil,
                zipped: Bool = true)
    {
      self.name        = name
      self.contentType = contentType
      self.content     = content
      self.isGZipped   = zipped
    }
  }
  
  let fileManager     : FileManager
  let lookupDirectory : URL
  
  /**
   * The modules in which classes are looked up by name, in order of
   * preference. Defaults to the module of the `sourceType` passed to the
   * initializer (usually the application module), followed by any extra
   * modules passed to the initializer and the SwiftObjects module itself.
   *
   * Classes in other modules are still found via the ``SwiftTypeIndex``, the
   * list only determines which class wins if several modules contain one
   * with the same name.
   */
  public var lookupModules : [ String ] {
    get { lock.lock(); defer { lock.unlock() }; return _lookupModules }
    set { lock.lock(); defer { lock.unlock() }; _lookupModules = newValue }
  }
  private var _lookupModules : [ String ]
  
  var classes           : [ String : AnyClass ]
  var missClass         = Set<String>()
  var resourceCache     = [ String : URL ]()
  var resourceMissCache = Set<String>()
  var memoryResources   = [ String : InMemoryResource ]()
  
  /**
   * Creates a resource manager which resolves resources relative to the
   * directory of the given source file.
   *
   * - Parameters:
   *   - sourceFile:       The file resources are looked up relative to,
   *                       defaults to the file of the caller.
   *   - sourceType:       A type in the application module, used to derive
   *                       the primary module for class lookups.
   *   - defaultFramework: An explicit name for the primary lookup module,
   *                       overrides the module derived from `sourceType`.
   *   - modules:          Names of additional Swift modules to look up
   *                       classes in, in order of preference, e.g. the
   *                       module of a component library. Classes in other
   *                       modules are still found, the list only decides
   *                       which one wins for ambiguous names.
   *   - classes:          Explicitly registered classes, keyed by name.
   */
  public init<T>(sourceFile: StaticString = #filePath, sourceType: T.Type,
                 defaultFramework: String? = nil, modules: [ String ] = [],
                 _ classes : [ String : AnyClass ] = [:])
  {
    fileManager = FileManager.default
    
    let fn = URL(fileURLWithPath: "\(sourceFile)")
    lookupDirectory = fn.deletingLastPathComponent()
    
    let appModule = defaultFramework ?? SOGetPackageName(sourceType)
    let ownModule = SOGetPackageName(WOComponent.self)
    var lookupModules = [ String ]()
    for module in [ appModule ] + modules + [ ownModule ]
    where !module.isEmpty && !lookupModules.contains(module)
    {
      lookupModules.append(module)
    }
    _lookupModules = lookupModules
    
    self.classes = classes
    
    super.init()
  }
  
  /**
   * Explicitly registers classes under their simple name. This is only
   * required for classes the automatic lookup can't find, e.g. private or
   * generic classes, or to override which class is used for a name.
   */
  open func register(_ classes: AnyClass...) {
    lock.lock(); defer { lock.unlock() }
    for cls in classes {
      let fqn = "\(cls)"
      self.classes[fqn] = cls
      self.missClass.remove(fqn)
    }
  }
  
  open func expose(_ resources: InMemoryResource...) {
    for resource in resources {
      memoryResources[resource.name] = resource
    }
  }
  
  override open func lookupClass(_ name: String) -> AnyClass? {
    return lookupClass(name) { _ in true }
  }
  
  /**
   * Looks up a class by name, and if multiple classes with that name are
   * loaded, picks the first one matching the given type.
   */
  override open func lookupClass<T>(_ name: String, type: T.Type) -> T.Type? {
    guard let cls = lookupClass(name, matching: { $0 is T.Type })
    else { return nil }
    guard let tcls = cls as? T.Type else {
      log.trace("found class, but it is not a \(type):", name)
      return nil
    }
    return tcls
  }
  
  private func lookupClass(_ name: String,
                           matching matches: (AnyClass) -> Bool) -> AnyClass?
  {
    lock.lock(); defer { lock.unlock() }
    
    if let cls = classes[name] { return cls }
    if missClass.contains(name) { return nil }
    
    let candidates = discoverClasses(named: name)
    guard !candidates.isEmpty else {
      log.trace("did not find class:", name, "in:", _lookupModules)
      missClass.insert(name)
      return nil
    }
    
    // Do not cache a type mismatch (the class exists, it is just not what
    // this particular lookup wanted). Return the first candidate so that the
    // caller can report the mismatch.
    guard let cls = candidates.first(where: matches) else {
      return candidates.first
    }
    if candidates.count > 1 {
      log.warn("multiple classes named", name, "found:",
               candidates.map { _typeName($0, qualified: true) },
               "using:", _typeName(cls, qualified: true))
    }
    classes[name] = cls
    return cls
  }
  
  /**
   * Returns all loaded classes with the given simple name, in order of
   * preference: classes in the ``lookupModules`` first, then everything the
   * ``SwiftTypeIndex`` found in the other loaded images.
   *
   * Must be called with the lock held.
   */
  private func discoverClasses(named name: String) -> [ AnyClass ] {
    var candidates = [ AnyClass ]()
    var seen       = Set<ObjectIdentifier>()
    func add(_ cls: AnyClass) {
      if seen.insert(ObjectIdentifier(cls)).inserted { candidates.append(cls) }
    }
    
    for module in _lookupModules {
      if let cls = SOGetClassByName(name, module) { add(cls) }
    }
    
    for entry in SwiftTypeIndex.classes(named: name) {
      if let cls = entry.resolve() { add(cls) }
    }
    return candidates
  }
  
  func cacheKeyForResourceNamed(_ name: String, languages: [ String ] = [])
    -> String
  {
    return name + "::" + languages.joined(separator: ",")
  }
  
  override open func urlForResourceNamed(_ name: String,
                                         languages: [ String ] = []) -> URL?
  {
    let key = cacheKeyForResourceNamed(name, languages: languages)
    
    lock.lock(); defer { lock.unlock() }
    
    if let url = resourceCache[key]    { return url }
    if resourceMissCache.contains(key) { return nil }
    
    let rURL = lookupDirectory.appendingPathComponent(name)
    if fileManager.fileExists(atPath: rURL.path) {
      resourceCache[key] = rURL
      return rURL
    }
    
    let cURL = lookupDirectory.appendingPathComponent("Components")
                              .appendingPathComponent(name)
    if fileManager.fileExists(atPath: cURL.path) {
      resourceCache[key] = cURL
      return cURL
    }

    log.trace("did not find resource:", name)
    resourceMissCache.insert(key)
    return nil
  }

  override open func dataForResourceNamed(_ name: String,
                                          languages: [ String ] = [])
                     -> Data?
  {
    if let mr = memoryResources[name] {
      return mr.content
    }
    guard let url = urlForResourceNamed(name, languages: languages) else {
      return nil
    }
    
    return try? Data(contentsOf: url)
  }

  override open func urlForResourceNamed(_ name: String, bundle: String?,
                                         languages: [ String ],
                                         in context: WOContext) -> String?
  {
    // TODO: crappy way to detect whether a resource is available
    guard memoryResources[name] != nil ||
          dataForResourceNamed("www/"+name, languages: languages) != nil else {
      return nil
    }

    return context.urlWithRequestHandlerKey("wr", path: name)
  }
}

