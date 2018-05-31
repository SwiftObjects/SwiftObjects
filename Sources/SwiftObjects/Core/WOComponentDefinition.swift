//
//  WOComponentDefinition.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * The component definition contains the information required to construct
 * a WOComponent object. That is, the component class and its template.
 */
public protocol WOComponentDefinition {
  
  /**
   * Instantiate the WOComponent represented by the definition.
   *
   * Important: the template must be set so that the subcomponent faults can be
   * properly instantiated.
   */
  func instantiateComponent(using resourceManager: WOResourceManager,
                            in context: WOContext) -> WOComponent?
  
  var template : WOTemplate? { get set }
  
  func touch()
  
  /**
   * Load the template using a TemplateBuilder. This is called by
   * `definitionForComponent()` of WOResourceManager.
   *
   * The arguments are URLs so that we can load resources from JAR archives.
   *
   * @param _type - select the TemplateBuilder, either 'Wrapper' or 'WOx'
   * @param _templateURL - URL pointing to the template
   * @param _wodURL      - URL pointing to the wod
   * @param _rm      - context used for performing class name lookups
   * @return true if the loading was successful, false otherwise
   */
  func load(using type: String, at url: URL, definitionsAt defURL: URL?,
            using resourceManager: WOResourceManager) throws

  /**
   * This is called by instantiateComponent() to instantiate the faults of the
   * child components.
   *
   * @param _rm       - the resource manager used for child's resource lookups
   * @param _template - the template which contains the child infos
   * @param _ctx      - the context to instantiate the components in
   * @return a Map of WOComponentReference names and their associated component
   */
  func instantiateChildComponents(from template: WOTemplate,
                                  in   context: WOContext,
                                  using resourceManager: WOResourceManager)
       -> [ String : WOComponent ]
}

open class WODefaultComponentDefinition : WOComponentDefinition,
                                          SmartDescription
{
  
  open var name           : String
  open var componentClass : WOComponent.Type
  open var template       : WOTemplate?
  open var lastUse        = Date()
  
  public init(name: String, componentClass: WOComponent.Type) {
    self.name           = name
    self.componentClass = componentClass
  }
  
  open func instantiateComponent(using resourceManager: WOResourceManager,
                                 in context: WOContext) -> WOComponent?
  {
    // TODO: port me
    
    /* Allocate component. We do not use a specific constructor because
     * this would require all subclasses to implement it. Which is clumsy Java
     * crap.
     */
    var component = componentClass.init()
    
    /* Set the name of the component. This is important because not all
     * components need to have a strictly associated class (eg templates w/o
     * a class or scripted components)
     */
    if !name.isEmpty {
      component._wcName = name
    }
    
    /* Initialize component for a given context. Note that the component may
     * choose to return a replacement.
     */
    guard let initializedComponent = component.initWithContext(context) else {
      context.log.warn("could not init component:", component)
      return nil
    }
    component = initializedComponent
    
    if let template = template {
      // TBD: We push the RM to the children, but NOT to the component. Thats
      //      kinda weird? We push the RM to the children to preserve the
      //      lookup context (eg framework local resource lookup).
      let childComponents = instantiateChildComponents(from  : template,
                                                       in    : context,
                                                       using : resourceManager)
      component.subcomponents = childComponents
      component.template      = template
    }
    else {
      context.log.trace("didn't push a template to component:", component)
    }

    return component
  }
  
  public func instantiateChildComponents(from template: WOTemplate,
                                         in   context: WOContext,
                                         using resourceManager: WOResourceManager)
              -> [ String : WOComponent ]
  {
    let childInfos = template.subcomponentInfos
    var childComponents = [ String : WOComponent ]()
    childComponents.reserveCapacity(childInfos.count)
    
    for ( k, childInfo ) in childInfos {
      /* setup fault with name, bindings and the resource manager */
      let fault = WOComponentFault()
      fault.cfName          = childInfo.componentName
      fault.wocBindings     = childInfo.bindings
      fault.resourceManager = resourceManager
      
      guard let child = fault.initWithContext(context) else {
        continue
      }
      childComponents[k] = child
    }
    return childComponents
  }

  open func touch() {
    lastUse = Date()
  }
  
  open func load(using type: String, at url: URL, definitionsAt defURL: URL?,
                 using resourceManager: WOResourceManager) throws
  {
    guard template == nil else { return } // already loaded
    guard type == "WOWrapper" else { throw Error.unsupportedBuilderType(type) }
    
    let builder : WOTemplateBuilder = WOWrapperTemplateBuilder()
    
    do {
      template = try builder.buildTemplate(for: url, bindingsURL: defURL,
                                           using: resourceManager)
    }
    catch {
      let info = "[Could not build template: \(url.lastPathComponent)]"
      template = WOTemplate(url: url, rootElement: WOStaticHTMLElement(info))
      throw error
    }
  }
  
  enum Error : Swift.Error {
    case unsupportedBuilderType(String)
  }

  // MARK: - Description
  
  open func appendToDescription(_ ms: inout String) {
    ms += " "
    ms += name

    if componentClass != WOComponent.self {
      ms += "(\(componentClass))"
    }
    
    if let template = template {
      ms += " loaded=\(template)"
    }
    else {
      ms += " not-loaded"
    }
  }
}
