//
//  WOResourceManager.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/*
 * Manages access to resources associated with WOApplication.
 *
 * ## Component Discovery and Page Creation in SOPE
 *
 * All WO code uses either directly or indirectly the WOResourceManager's
 * `-pageWithName:languages:` method to instantiate WO components.
 *
 * This methods works in three steps:
 * - discovery of files associated with the component
 * - creation of a proper WOComponentDefinition, which is some kind
 *   of 'blueprint' or 'class' for components
 * - component instantiation using the definition
 *
 * All the instantiation/setup work is done by a component definition, the
 * resource manager is only responsible for managing those 'blueprint'
 * resources.
 *
 * If you want to customize component creation, you can supply your
 * own WOComponentDefinition in a subclass of WOResourceManager by
 * overriding:
 *
 *     - (WOComponentDefinition *)definitionForComponent:(id)_name
 *       inFramework:(NSString *)_frameworkName
 *       languages:(NSArray *)_languages</pre>
 *
 * THREAD: TODO
 */
public protocol WOResourceManager {
  
  var log : WOLogger { get }

  // MARK: - Templates

  /**
   * Locates the component definition for the given component name and
   * instantiates that definition. No other magic involved.
   * Note that the WOComponent will (per default) use templateWithName() to
   * locate its template, which involves the same WOComponentDefinition.
   *
   * This method gets called by WOApplication.pageWithName(), but also by
   * the WOComponentFault. (TBD: when to use this method directly?)
   *
   * @param _name - name of page to lookup and instantiate
   * @param _ctx  - the WOContext to instantiate the page in
   * @return an instantiated WOComponent, or nil on error
   */
  func pageWithName(_ name: String, in context: WOContext?) -> WOComponent?

  /**
   * Locates the component definition for the given component name and
   * returns the associated dynamic element tree.
   * This is called by WOComponent when it requests its template for request
   * processing or rendering.
   *
   * @param _name  - name of template (same like the components name)
   * @param _langs - languages to check
   * @param _rm    - class context in which to parse template class names
   * @return the parsed template
   */
  func templateWithName(_ name: String, languages: [ String ],
                        using resourceManager: WOResourceManager) -> WOElement?


  // MARK: - Component Definitions

  /**
   * This is the primary method to locate a component and return a
   * WOComponentDefinition describing it. The definition is just a blueprint,
   * not an actual instance of the component.
   *
   * The method calls load() on the definition, this will actually load the
   * template of the component.
   *
   * All the caching is done by the wrapping method.
   *
   * @param _name  - the name of the component to load (eg 'Main')
   * @param _langs - the languages to check
   * @param _rm    - the RM used to lookup classes
   * @return a WOComponentDefinition which represents the specific component
   */
  func templateWithName(_ name: String, languages: [ String ],
                        using resourceManager: WOResourceManager)
       -> WOComponentDefinition?

  /**
   * This is the primary method to locate a component and return a
   * WOComponentDefinition describing it. The definition is just a blueprint,
   * not an actual instance of the component.
   *
   * The method calls load() on the definition, this will actually load the
   * template of the component.
   *
   * All the caching is done by the wrapping method.
   *
   * @param _name  - the name of the component to load (eg 'Main')
   * @param _langs - the languages to check
   * @param _rm    - the RM used to lookup classes
   * @return a WOComponentDefinition which represents the specific component
   */
  func definitionForComponent(_ name: String, languages: [ String ],
                               using resourceManager: WOResourceManager)
       -> WOComponentDefinition?

  func _cachedDefinitionForComponent(_ name: String, languages: [ String ])
       -> WOComponentDefinition?
  func _cacheDefinition(_ def: WOComponentDefinition,
                        for name: String, languages: [ String ])
       -> WOComponentDefinition

  // MARK: - Resources

  /**
   * Returns the internal resource URL for a resource name and a set of language
   * codes.
   * The default implementation just returns null, subclasses need to override
   * the method to implement resource lookup.
   *
   * Important: the returned URL is usually a file: or jar: URL for use in
   * server side code. It is NOT the URL which is exposed to the browser/client.
   */
  func urlForResourceNamed(_ name: String, languages: [ String ]) -> URL?


  /**
   * Opens a stream to the given resource and loads the content into a byte
   * array.
   *
   * @param _name  - name of the resource to be opened
   * @param _langs - array of language codes (eg [ 'de', 'en' ])
   * @return byte array with the contents, or null if the resource is missing
   */
  func dataForResourceNamed(_ name: String, languages: [ String ]) -> Data?

  /**
   * Returns the client side (browser) URL of a *public* resource. The
   * default implementation defines 'public' resources as those living in the
   * 'www' directory, that is, the method prefixes the resource with 'www/'.
   *
   * This method is used to resolve 'filename' bindings in dynamic elements.
   *
   * @param _name   - name of the resource
   * @param _fwname - unused by the default implementation, a framework name
   * @param _langs  - a set of language codes
   * @param _ctx    - a WOContext, this will be asked to construct the URL
   * @return a URL which allows the browser to retrieve the given resource
   */
  func urlForResourceNamed(_ name: String, bundle: String?,
                           languages: [ String ],
                           in context: WOContext) -> String?


  // MARK: - Strings

  /**
   * Converts the _langs to an array and calls the array based
   * localForLanguages().
   * Which returns the Swift Locale object for the given _langs.
   *
   * This method is called by the WOContext.deriveLocale() method.
   *
   * @param _langs - languages to check
   * @return the Locale object for the given languages, or Locale.US
   */
  func localeForLanguages(_ languages: [ String ]) -> Locale

  func stringTableWithName(_ table: String, framework: String?,
                           languages: [ String ]) -> Bundle?

  /**
   * Retrieves the string table using stringTableWithName(), and then attempts
   * to resolve the key. If the key could not be found, the _default is returned
   * instead.
   *
   * @param _key     - string to lookup (eg: 05_private)
   * @param _table   - name of table, eg null, LocalizableStrings, or Main
   * @param _default - string to use if the key could not be resolved
   * @param _fwname  - name of framework containing the resource, or null
   * @param _langs   - languages to check for the key
   * @return the resolved string, or the the _default
   */
  func stringForKey(_ key: String, in table: String?, default: String?,
                    framework: String?, languages: [ String ]) -> String?


  // MARK: - Reflection


  /**
   * Used by the template parser to lookup a component name. A component class
   * does not necessarily match a Swift class, eg a component written in Python
   * might use a single "WOPyComponent" class for all Python components.
   *
   * However, the default implementation just calls lookupClass() with the
   * given name :-)
   *
   * Note: this method is ONLY used for WOComponents.
   *
   * @param _name - the name of the component to lookup
   * @return a Class responsible for the component with the given name
   */
  func lookupComponentClass(_ name: String) -> WOComponent.Type?

  /**
   * Used by the template parser to lookup a dynamic element name.
   *
   * However, the default implementation just calls lookupClass() with the
   * given name :-)
   *
   * Note: this method is used for WODynamicElement classes only.
   *
   * @param _name - the name of the element to lookup
   * @return a Class responsible for the element with the given name
   */
  func lookupDynamicElementClass(_ name: String) -> WODynamicElement.Type?

  /**
   * This is invoked by code which wants to instantiate a "direct action". This
   * can be a WOAction subclass, or a WOComponent.
   *
   * Note that the context is different to lookupComponentClass(), which
   * can return a WOComponent or WODynamicElement. This method usually returns a
   * WOComponent or a WOAction.
   *
   * @param _name - the name of the action or class to lookup
   * @return a Class to be used for instantiating the given action object
   */
  func lookupDirectActionClass(_ name: String) -> WODirectAction.Type?
  
  /**
   * A generic class lookup function.
   */
  func lookupClass(_ name: String) -> AnyClass?
}

public extension WOResourceManager { // default implementation

  public var log : WOLogger { return WOPrintLogger.shared }

  public func pageWithName(_ name: String, in context: WOContext?)
              -> WOComponent?
  {
    log.trace("pageWithName(\(name), \(context?.description ?? "-"))")
    guard let context = context else {
      log.error("got no context to lookup page:", name, self)
      return nil
    }
    
    /* Note: we pass in the root resource manager as the class resolver. This
     *       is used in WOComponentDefinition.load() which is triggered along
     *       the way (and needs the clsctx to resolve WOElement names in
     *       templates)
     */
    let rm = context.rootResourceManager ?? self
    
    /* the underscore method does all the caching and then triggers 'da real
     * definitionForComponent() method.
     */
    let langs = context.languages
    guard let cdef = _definitionForComponent(name, languages: langs,
                                             using: rm) else {
      log.trace("  found no cdef for component:", name, self)
      return nil
    }
    
    return cdef.instantiateComponent(using: self, in: context)
  }

  public func templateWithName(_ name: String, languages: [ String ],
                               using resourceManager: WOResourceManager)
              -> WOElement?
  {
    guard let cdef = _definitionForComponent(name, languages: languages,
                                             using: resourceManager) else {
      return nil
    }
    
    return cdef.template
  }

  /**
   * This manages the caching of WOComponentDefinition's. When asked for a
   * definition it checks the cache and if it does not find one, it will call
   * the primary load method: definitionForComponent().
   */
  func _definitionForComponent(_ name: String, languages: [ String ],
                               using resourceManager: WOResourceManager)
       -> WOComponentDefinition?
  {
    if let cdef = _cachedDefinitionForComponent(name, languages: languages) {
      // TODO: add a miss marker
      cdef.touch()
      return cdef
    }
    
    guard let cdef = definitionForComponent(name,
                                            languages: languages,
                                            using: resourceManager) else
    {
      return nil
    }
    
    return _cacheDefinition(cdef, for: name, languages: languages)
  }

  /**
   * This is the primary method to locate a component and return a
   * WOComponentDefinition describing it. The definition is just a blueprint,
   * not an actual instance of the component.
   *
   * The method calls load() on the definition, this will actually load the
   * template of the component.
   *
   * All the caching is done by the wrapping method.
   *
   * @param _name  - the name of the component to load (eg 'Main')
   * @param _langs - the languages to check
   * @param _rm    - the RM used to lookup classes
   * @return a WOComponentDefinition which represents the specific component
   */
  func templateWithName(_ name: String, languages: [ String ],
                        using resourceManager: WOResourceManager)
       -> WOComponentDefinition?
  {
    var type         = "WOx"
    var templateData : URL? = nil
    var cls          = lookupComponentClass(name)
    
    if cls == nil {
      log.trace("rm does not serve the class, check for templates:", name)
      
      /* check whether its a component w/o a class */
      templateData = urlForResourceNamed(name + ".wox", languages: languages)
      if templateData == nil {
        type = "WOWrapper"
        templateData = urlForResourceNamed(name + ".html", languages: languages)
      }
      
      if templateData == nil {
        return nil /* did not find a template */
      }
      
      cls = WOComponent.self
    }
    
    let cdef = WODefaultComponentDefinition(name: name, componentClass: cls!)
    
    if templateData == nil {
      templateData = urlForResourceNamed(name + ".wox", languages: languages)
    }
    if templateData == nil {
      type = "WOWrapper"
      templateData = urlForResourceNamed(name + ".html", languages: languages)
    }
    
    let wodData : URL? = {
      guard type == "WOWrapper" else { return nil }
      return urlForResourceNamed(name + ".wod", languages: languages)
    }()
    
    guard let resolvedURL = templateData else {
      log.trace("component has no template:", name)
      return cdef
    }
    
    /* load it */
    
    do {
      try cdef.load(using: type, at: resolvedURL, definitionsAt: wodData,
                    using: resourceManager)
      return cdef
    }
    catch {
      log.error("Failed to load template of component:",
                name, resolvedURL, cdef)
      return nil
    }
  }
  
  func genCacheKey(_ name: String, _ languages: [ String ]) -> String {
    if languages.isEmpty { return name }
    return name + ":" + languages.joined(separator: ":")
  }
  
  public func dataForResourceNamed(_ name: String, languages: [ String ] = [])
              -> Data?
  {
    guard let url = urlForResourceNamed(name, languages: languages) else {
      return nil
    }
    
    return try? Data(contentsOf: url)
  }

  public func urlForResourceNamed(_ name: String, bundle: String?,
                                  languages: [ String ],
                                  in context: WOContext) -> String?
  {
    // TODO: crappy way to detect whether a resource is available
    guard let _ = dataForResourceNamed("www/"+name, languages: languages) else {
      return nil
    }
    
    return context.urlWithRequestHandlerKey("wr", path: name)
  }

  public func localeForLanguages(_ languages: [ String ]) -> Locale {
    if languages.isEmpty { return Locale(identifier: "en_US") }
    return Locale(identifier: languages[0]) // TODO: loop and find?
  }

  public func stringTableWithName(_ table: String, framework: String?,
                                  languages: [ String ]) -> Bundle?
  {
    return Bundle.main
  }

  public func stringForKey(_ key: String, in table: String?, default: String?,
                           framework: String?, languages: [ String ]) -> String?
  {
    guard let rb = stringTableWithName(table ?? "Default",
                                       framework: framework,
                                       languages: languages) else {
      return `default` ?? key
    }

    // FIXME
    return rb.localizedString(forKey: key, value: `default`, table: table)
  }

}
  
public extension WOResourceManager { // Convenience
    
  public func stringForKey(_ key: String, default: String? = nil,
                           framework: String? = nil, languages: [ String ] = [])
              -> String?
  {
    return stringForKey(key, in: nil, default: `default`, framework: framework,
                        languages: languages)
  }
}

open class WOResourceManagerBase : WOResourceManager, SmartDescription {
  
  open let lock = Foundation.NSLock()
  open let log  : WOLogger = WOPrintLogger.shared
  
  public init() {}
  
  // MARK: - Definition Caching
  
  var componentDefinitions : [ String : WOComponentDefinition ]?
  
  open func _cachedDefinitionForComponent(_ name: String, languages: [ String ])
            -> WOComponentDefinition?
  {
    lock.lock(); defer { lock.unlock() }
    guard let componentDefinitions = componentDefinitions else { return nil }
    return componentDefinitions[genCacheKey(name, languages)]
  }
  
  open func _cacheDefinition(_ def: WOComponentDefinition,
                             for name: String, languages: [ String ])
            -> WOComponentDefinition
  {
    lock.lock(); defer { lock.unlock() }
    componentDefinitions?[genCacheKey(name, languages)] = def
    return def
  }
  
  
  // MARK: - Load Definition
  
  open func definitionForComponent(_ name: String, languages: [ String ],
                                   using resourceManager: WOResourceManager)
            -> WOComponentDefinition?
  {
    /*
     * Note: a 'package component' is a component which has its own package,
     *       eg: org.opengroupware.HomePage with subelements 'HomePage.class',
     *       'HomePage.html' and 'HomePage.wod'.
     */
    // TODO: complete me
    // TODO: port WOx template support
    
    // TBD: What is the RM being passed in good for? Don't remember :-)
    // assert(resourceManager === self)
    
    let cls          = lookupComponentClass(name)
    let templateData = urlForResourceNamed(name + ".html", languages: languages)
    
    if cls == nil && templateData == nil {
      log.trace("could not locate component:", name)
      return nil
    }
    
    let cdef = WODefaultComponentDefinition(
                 name: name, componentClass: cls ?? WOComponent.self)
    
    if let templateData = templateData {
      let type = "WOWrapper" // vs WOx
      let wodData = urlForResourceNamed(name + ".wod" , languages: languages)
      
      do {
        try cdef.load(using: type, at: templateData, definitionsAt: wodData,
                      using: self)
      }
      catch {
        log.error("Could not load template:", templateData, error)
        return nil
      }
    }
    
    return cdef
  }

  
  // MARK: - Lookups
  
  open func urlForResourceNamed(_ name: String,
                                languages: [ String ] = []) -> URL?
  {
    // ABSTRACT
    return nil
  }

  open func lookupClass(_ name: String) -> AnyClass? {
    // ABSTRACT
    return nil
  }

  open func lookupClass<T>(_ name: String, type: T.Type) -> T.Type? {
    guard let cls  = lookupClass(name) else { return nil }
    guard let tcls = cls as? T.Type else {
      log.trace("found class, but it is not a \(type):", name)
      return nil
    }
    return tcls
  }

  open func lookupComponentClass(_ name: String) -> WOComponent.Type? {
    return lookupClass(name, type: WOComponent.self)
  }
  
  open func lookupDynamicElementClass(_ name: String) -> WODynamicElement.Type?
  {
    return WOElementNames[name]
        ?? lookupClass(name, type: WODynamicElement.self)
  }
  
  open func lookupDirectActionClass(_ name: String) -> WODirectAction.Type? {
    return lookupClass(name, type: WODirectAction.self)
  }
  
  
  // MARK: - Dupes to workaround protocol subclassing issue

  open func dataForResourceNamed(_ name: String, languages: [ String ] = [])
            -> Data?
  {
    guard let url = urlForResourceNamed(name, languages: languages) else {
      return nil
    }
    
    return try? Data(contentsOf: url)
  }
  
  open func urlForResourceNamed(_ name: String, bundle: String?,
                                languages: [ String ],
                                in context: WOContext) -> String?
  {
    // TODO: crappy way to detect whether a resource is available
    guard let _ = dataForResourceNamed("www/"+name, languages: languages) else {
      return nil
    }
    
    return context.urlWithRequestHandlerKey("wr", path: name)
  }
  

  // MARK: - Description
  
  open func appendToDescription(_ ms: inout String) {
    lock.lock(); defer { lock.unlock() }
    if let cd = componentDefinitions, !cd.isEmpty {
      ms += " #cdefs=\(cd.count)"
    }
  }
}
