//
//  WOActionURL.swift
//  SwiftObjects
//
//  Created by Helge Hess on 01.06.18.
//

/**
 * Can be used to generate a dynamic link which returns a page (or some other
 * WOActionResults).
 *
 * Sample .html:
 *
 *     <a href="<wo:Link/>">login</a>
 *
 * Sample .wod:
 *
 *     Link: WOActionURL {
 *         actionClass      = "Main";
 *         directActionName = "login";
 *     }
 *
 * Renders:
 *
 *     <a href="/App/x/LeftMenu/default">[sub-template]</a>
 *
 * Bindings:
 * ```
 *   href             [in] - string
 *   directActionName [in] - string
 *   actionClass      [in] - string
 *   pageName         [in] - string
 *   action           [in] - action
 * ```
 */
open class WOActionURL : WOHTMLDynamicElement {
  
  let link     : WOLinkGenerator?
  let template : WOElement?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    link = WOLinkGenerator.linkGenerator(for: &bindings)
    self.template = template
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    try link?.takeValues(from: request, in: context)
    try template?.takeValues(from: request, in: context)
  }
  
  override
  open func invokeAction(for request: WORequest, in context: WOContext) throws
            -> Any?
  {
    if context.elementID == context.senderID {
      guard let link = link else {
        context.log.warn("no action configured for link invocation", self)
        return nil
      }
      
      return try link.invokeAction(for: request, in: context)
    }
    
    return try template?.invokeAction(for: request, in: context)
  }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    if !context.isRenderingDisabled, let link = link,
       let value = link.fullHref(in: context)
    {
      try response.appendContentHTMLAttributeValue(value)
    }
    
    try template?.append(to: response, in: context)
  }
  
  override open func walkTemplate(using walker : WOElementWalker,
                                  in   context : WOContext) throws
  {
    try template?.walkTemplate(using: walker, in: context)
  }

  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if let link = link { ms += " link=\(link)" }
  }
}
