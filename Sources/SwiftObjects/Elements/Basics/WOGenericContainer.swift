//
//  WOGenericContainer.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * This renders an arbitrary (HTML) tag. It allows you to make attributes of the
 * tag dynamic. WOGenericContainer is for elements which have close tags (like
 * font), for empty elements use WOGenericElement (like `<br/>`).
 *
 * Sample:
 *
 *     MyFont: WOGenericContainer {
 *         elementName = "font";
 *         color       = currentColor;
 *     }
 *
 * Renders:
 * ```
 *   <font color="[red]">[sub-template]</font>
 * ```
 *
 * Bindings:
 * ```
 *   tagName [in] - string
 *   - all other bindings are mapped to tag attributes</pre>
 * ```
 */
open class WOGenericContainer : WOGenericElement {
  
  let template  : WOElement?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
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
    return try template?.invokeAction(for: request, in: context)
  }
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else {
      try template?.append(to: response, in: context)
      return
    }
    
    let cursor = context.cursor
    let omit   = omitTags?.boolValue(in: cursor) ?? false
    let tag    = !omit ? tagName?.stringValue(in: cursor) : nil
    
    if let tag = tag {
      try response.appendBeginTag(tag)
      try coreAttributes?.append(to: response, in: context)
      try appendExtraAttributes(to: response, in: context)
      
      if template != nil || !context.generateXMLStyleEmptyElements {
        try response.appendBeginTagEnd()
      }
      else {
        try response.appendBeginTagClose(context.closeAllElements)
        return
      }
    }
    
    /* add content */
    try template?.append(to: response, in: context)
    
    /* close tag */
    if let tag = tag { try response.appendEndTag(tag) }
  }

  override open func walkTemplate(using walker : WOElementWalker,
                                  in   context : WOContext) throws
  {
    try template?.walkTemplate(using: walker, in: context)
  }
}

