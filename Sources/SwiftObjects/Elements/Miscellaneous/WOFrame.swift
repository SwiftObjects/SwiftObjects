//
//  WOFrame.swift
//  SwiftObjects
//
//  Created by Helge Hess on 02.06.18.
//

/**
 * Can be used to generate a `<frame>` tag with a dynamic content URL.
 *
 * Sample:
 * ```
 *   Frame: WOFrame {
 *     actionClass      = "LeftMenu";
 *     directActionName = "default";
 *   }
 * ```
 *
 * Renders:<pre>
 * ```
 *   <frame src="/App/x/LeftMenu/default">[sub-template]</frame>
 * ```
 *
 * Bindings:
 * ```
 *   name             [in] - string
 *   href             [in] - string
 *   directActionName [in] - string
 *   actionClass      [in] - string
 *   pageName         [in] - string
 *   action           [in] - action
 * ```
 */
open class WOFrame : WOHTMLDynamicElement {
  
  let name     : WOAssociation?
  let link     : WOLinkGenerator?
  let template : WOElement?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    self.name     = bindings.removeValue(forKey: "name")
    self.link     = WOLinkGenerator.linkGenerator(for: &bindings)
    self.template = template
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  override open func takeValues(from request: WORequest,
                                in context: WOContext) throws
  {
    try link?.takeValues(from: request, in: context)
    try template?.takeValues(from: request, in: context)
  }
  
  override open func invokeAction(for request : WORequest,
                                  in  context : WOContext) throws -> Any?
  {
    return try template?.invokeAction(for: request, in: context)
  }
  
  override open func walkTemplate(using walker : WOElementWalker,
                                  in   context : WOContext) throws
  {
    try template?.walkTemplate(using: walker, in: context)
  }
  
  
  // MARK: - Rendering

  open var frameTag : String { return "frame" }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else {
      try template?.append(to: response, in: context)
      return
    }
    
    let tag = frameTag
    
    try response.appendBeginTag(tag)
    
    if let s = name?.stringValue(in: context.cursor) {
      try response.appendAttribute("name", s)
    }
    
    if let url = link?.fullHref(in: context) {
      try response.appendAttribute("src", url)
    }
    
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagEnd()
    
    try template?.append(to: response, in: context)
    
    try response.appendEndTag(tag)
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingToDescription(&ms, "name", name)
    
    if let link = link { ms += " src=\(link)" }
  }
}
