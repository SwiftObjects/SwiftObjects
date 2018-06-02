//
//  WOSwitchComponent.swift
//  SwiftObjects
//
//  Created by Helge Hess on 02.06.18.
//

/**
 * Dynamically replace components in a template.
 *
 * Bindings:
 * ```
 *   WOComponentName - String [in]
 *   other bindings  - will be bindings for the instantiated component
 * ```
 */
open class WOSwitchComponent : WOHTMLDynamicElement {
  
  let componentName : WOAssociation?
  let template      : WOElement?
  let bindings      : Bindings
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    componentName = bindings.removeValue(forKey: "componentName")
    self.template = template
    
    bindings.removeValue(forKey: "NAME")
    self.bindings = bindings
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  func lookupComponent(named name: String, in context: WOContext)
       -> WOComponent?
  {
    guard let c = context.component?.pageWithName(name) else {
      context.log.warn("switch didn't find:", name)
      return nil
    }
    
    c.parentComponent = context.component
    c.wocBindings     = bindings
    return c
  }
  
  func run<T>(in context: WOContext, default d: T,
              _ cb: ( WOComponent ) throws -> T)
         throws -> T
  {
    guard let name = componentName?.stringValue(in: context) else { return d }
    guard let c = lookupComponent(named:name, in: context)   else { return d }
    
    let cname = name.replacingOccurrences(of: ".", with: "_") // element-id
    context.appendElementIDComponent(cname)
    defer { context.deleteLastElementIDComponent() }
    
    context.enterComponent(c, content: template)
    defer { context.leaveComponent(c) }
    
    return try cb(c)
  }
  
  override open func takeValues(from request: WORequest,
                                in context: WOContext) throws
  {
    try run(in: context, default: Void()) { component in
      return try component.takeValues(from: request, in: context)
    }
  }
  
  override open func invokeAction(for request : WORequest,
                                  in  context : WOContext) throws -> Any?
  {
    return try run(in: context, default: nil) { component in
      return try component.invokeAction(for: request, in: context)
    }
  }
  
  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    try run(in: context, default: Void()) { component in
      return try component.append(to: response, in: context)
    }
  }

  override open func walkTemplate(using walker : WOElementWalker,
                                  in   context : WOContext) throws
  {
    try run(in: context, default: Void()) { component in
      return try component.walkTemplate(using: walker, in: context)
    }
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "componentName", componentName
    )
  }
}
