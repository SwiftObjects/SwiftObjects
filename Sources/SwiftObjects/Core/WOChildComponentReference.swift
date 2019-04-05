//
//  WOChildComponentReference.swift
//  SwiftObjects
//
//  Created by Helge Hess on 20.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

/**
 * This element is used to represent child components in template structures.
 * It retrieves the child component (usually a fault at the beginning) from
 * the component, pushes that to the stack and finally calls the appropriate
 * responder method on the child.
 */
open class WOChildComponentReference : WODynamicElement {
  
  let childName : String
  let template  : WOElement?
  
  public convenience init(name: String, template: WOElement?) {
    var b = Bindings()
    self.init(name: name, bindings: &b, template: template)
  }
  
  public required init(name: String, bindings: inout Bindings,
                       template: WOElement?)
  {
    self.childName = name
    self.template  = template
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  func child(in context: WOContext) -> WOComponent? {
    let log = context.log
    
    guard let parent = context.component else {
      log.error("did not find parent of child component:", childName)
      return nil
    }
    
    guard let child = parent.childComponent(with: childName) else {
      log.error("did not find child component", childName, "in parent:",
                parent, "reference:", self)
      return nil
    }
    
    return child
  }
  
  override open func takeValues(from request: WORequest,
                                in context: WOContext) throws
  {
    guard let child = child(in: context) else { return }
    
    context.enterComponent(child, content: template)
    defer { context.leaveComponent(child) }
    
    try child.takeValues(from: request, in: context)
  }
  
  override open func invokeAction(for request : WORequest,
                                  in  context : WOContext) throws -> Any?
  {
    guard let child = child(in: context) else { return nil }
    
    context.enterComponent(child, content: template)
    defer { context.leaveComponent(child) }
    
    return try child.invokeAction(for: request, in: context)
  }
  
  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    guard let child = child(in: context) else {
      try response.appendBeginTag("pre")
      try response.appendBeginTagEnd()
      try response.appendContentHTMLString("[missing component: \(childName)]")
      try response.appendEndTag("pre")
      return
    }
    
    context.enterComponent(child, content: template)
    defer { context.leaveComponent(child) }
    
    try child.append(to: response, in: context)
  }

  override open func walkTemplate(using walker : WOElementWalker,
                                  in   context : WOContext) throws
  {
    guard let child = child(in: context) else { return }
    
    context.enterComponent(child, content: template)
    defer { context.leaveComponent(child) }
    
    try child.walkTemplate(using: walker, in: context)
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    ms += " '\(childName)'"
    if template != nil { ms += " template" }
  }
}
