//
//  WOConditionalComment.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * This is for rendering an IE conditional comment. Looks like a comment to all
 * browsers but IE.
 *
 * Sample:
 *
 *     ShowIfIE5: WOConditionalComment {
 *         expression = "IE 5";
 *     }
 *
 * Renders:
 * ```
 *   <!--[if IE 5]>
 *     <p>Welcome to Internet Explorer 5.</p>
 *   <![endif]--&gt;</pre>
 * ```
 *
 * Bindings:
 * ```
 *   expression [in] - string
 *   feature    [in] - string
 *   value      [in] - string
 *   comparison [in] - string
 *   operator   [in] - string
 * ```
 */
open class WOConditionalComment : WOHTMLDynamicElement {
  
  let expression : WOAssociation?
  let feature    : WOAssociation?
  let value      : WOAssociation?
  let comparison : WOAssociation?
  let `operator` : WOAssociation?
  let template   : WOElement?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    expression = bindings.removeValue(forKey: "expression")
    feature    = bindings.removeValue(forKey: "feature")
    value      = bindings.removeValue(forKey: "value")
    comparison = bindings.removeValue(forKey: "comparison")
    `operator` = bindings.removeValue(forKey: "operator")
    
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
    
    /* start comment */
    
    try response.appendContentString("<!--[if ")

    if let s = `operator`?.stringValue(in: cursor) {
      try response.appendContentString(s)
    }
    if let s = feature?.stringValue(in: cursor) {
      try response.appendContentString(s)
    }
    if let s = comparison?.stringValue(in: cursor) {
      try response.appendContentString(" ")
      try response.appendContentString(s)
    }
    if let s = value?.stringValue(in: cursor) {
      try response.appendContentString(" ")
      try response.appendContentString(s)
    }
    if let s = expression?.stringValue(in: cursor) {
      try response.appendContentString(s)
    }
    
    try response.appendContentString("]>")
    
    /* embed content */
    
    try template?.append(to: response, in: context)
    
    /* close comment */
    try response.appendContentString("<![endif]-->")
  }

  override
  open func walkTemplate(using walker: WOElementWalker, in context: WOContext)
              throws
  {
    try template?.walkTemplate(using: walker, in: context)
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)

    WODynamicElement.appendBindingsToDescription(&ms,
      "expression", expression,
      "feature",    feature,
      "value",      value,
      "operator",   `operator`,
      "comparison", comparison
    )
  }
}
