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
 * A basic resource manager, which supports class registration and looks up
 * resources relative to some source file (using the #filename trick).
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
  
  let fileManager          : FileManager
  let lookupDirectory      : URL
  let defaultFrameworkName : String
  
  var classes              : [ String : AnyClass ]
  var missClass            = Set<String>()
  var resourceCache        = [ String : URL ]()
  var resourceMissCache    = Set<String>()
  var memoryResources      = [ String : InMemoryResource ]()
  
  public init<T>(sourceFile: StaticString = #file, sourceType: T.Type,
                 defaultFramework: String,
                 _ classes : [ String : AnyClass ] = [:])
  {
    fileManager = FileManager.default
    
    let fn = URL(fileURLWithPath: "\(sourceFile)")
    lookupDirectory = fn.deletingLastPathComponent()
    
    defaultFrameworkName = SOGetPackageName(sourceType,
                                            default: defaultFramework)
    
    self.classes = classes
    
    super.init()
  }
  
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
    lock.lock(); defer { lock.unlock() }
    
    if let cls = classes[name] { return cls }
    if missClass.contains(name) { return nil }
    
    guard let cls = SOGetClassByName(name, defaultFrameworkName) else {
      // log.warn("did not find class:", name, "in:", defaultFrameworkName)
      missClass.insert(name)
      return nil
    }
    
    classes[name] = cls
    
    return cls
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

