//
//  WOCompoundElement.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//

import Foundation

open class WOCompoundElement : WODynamicElement {
  
  let children : [ WOElement ]
  
  public init(children: [ WOElement ]) {
    self.children = children
    
    var bindings = Bindings()
    super.init(name: "Compound", bindings: &bindings, template: nil)
  }
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    if let template = template { children = [ template ]}
    else { children = [] }
    super.init(name: name, bindings: &bindings, template: nil)
  }
  
  public static func make(_ elements: WOElement...) -> WOElement {
    if elements.isEmpty { return WOStaticHTMLElement("") } // dummy
    if elements.count == 1 { return elements[0] }
    return WOCompoundElement(children: elements)
  }

  
  override open func takeValues(from request: WORequest,
                                in context: WOContext) throws
  {
    context.appendZeroElementIDComponent()
    defer { context.deleteLastElementIDComponent() }
    
    for element in children {
      try element.takeValues(from: request, in: context)
      context.incrementLastElementIDComponent()
    }
  }
  
  override open func invokeAction(for request: WORequest,
                                  in context: WOContext) throws -> Any?
  {
    context.appendZeroElementIDComponent()
    defer { context.deleteLastElementIDComponent() }
    
    for element in children {
      let result = try element.invokeAction(for: request, in: context)
      
      // TODO: This is somehwat incorrect, a matched action might indeed return
      //       null! (match marker in context?)
      if let result = result { return result }
      
      context.incrementLastElementIDComponent()
    }
    return nil
  }
  
  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    context.appendZeroElementIDComponent()
    defer { context.deleteLastElementIDComponent() }
    
    for element in children {
      try element.append(to: response, in: context)
      context.incrementLastElementIDComponent()
    }
  }
  
  override open func walkTemplate(using walker: WOElementWalker,
                                  in context: WOContext) throws
  {
    context.appendZeroElementIDComponent()
    defer { context.deleteLastElementIDComponent() }
    
    for element in children {
      guard try walker(self, element, context) else { break }
      context.incrementLastElementIDComponent()
    }
  }
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if children.isEmpty {
      ms += " no-children"
    }
    else if children.count == 1 {
      ms += " child=\(children[0])"
    }
    else {
      ms += " children=\(children)"
    }
  }
}
