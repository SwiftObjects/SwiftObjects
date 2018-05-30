//
//  WOResourceURL.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/*
 * Can be used to generate a dynamic link to a resource which is managed by
 * the framework.
 *
 * Sample .html:
 * ```
 *   <img src="<#Link/>" />
 * ```
 *
 * Sample .wod:
 * ```
 *   Link: WOResourceURL {
 *     filename = "lori.gif";
 *   }
 * ```
 *
 * Renders:
 * ```
 *   <a href="/App/x/LeftMenu/default">[sub-template]</a>
 * ```
 *
 * Bindings:
 * ```
 *   src              [in] - string
 *   directActionName [in] - string
 *   actionClass      [in] - string
 *   filename         [in] - string
 * ```
 *
 * TODO: document
 */
open class WOResourceURL : WOHTMLDynamicElement {
  
  let link     : WOLinkGenerator?
  let template : WOElement?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    link = WOLinkGenerator.resourceLinkGenerator(keyedOn: "src", for: &bindings)
    self.template = template
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    try template?.takeValues(from: request, in: context)
  }
  
  override
  open func invokeAction(for request: WORequest, in context: WOContext) throws
            -> Any?
  {
    // TODO: implement me: support 'data' bindings
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

