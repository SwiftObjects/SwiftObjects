//
//  WOGenericElement.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * This renders an arbitrary (HTML) tag. It allows you to make attributes of the
 * tag dynamic. WOGenericElement is for "empty" elements (like <br/>), for
 * elements with subelements use WOGenericContainer.
 *
 * Sample:
 *
 *     DynHR: WOGenericElement {
 *         elementName = "hr";
 *         border      = currentBorderWidth;
 *     }
 *
 * Renders:
 * ```
 *   <hr border="[1]" />
 * ```
 *
 * Bindings:
 * ```
 *   tagName [in] - string
 *   - all other bindings are mapped to tag attributes
 * ```
 *
 * Special +/- binding hack (NOTE: clases with WOHTMLElementAttributes)
 *
 * This element treats all bindings starting with either + or - as conditions
 * which decide whether a value should be rendered.
 * For example:
 *
 *     Font: WOGenericElement {
 *         elementName = "span";
 *
 *         +style = isCurrent;
 *         style  = "current"; // only applied if isCurrent is true
 *     }
 *
 * Further, this hack treats constant string conditions as
 * WOQualifierConditions allowing stuff like this:
 *
 *     FontOfScheduler: WOGenericElement {
 *         elementName = "span";
 *
 *         +style = "context.page.name = 'Scheduler'";
 *         style  = "current"; // only applied if isCurrent is true
 *     }
 *
 * Bindings (WOHTMLElementAttributes):
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg <input style="color:red;">)
 *   .key   [in]  - 'class' parameters (eg <input class="selected">)
 * ```
 */
open class WOGenericElement : WOHTMLDynamicElement {
  // TODO: maybe this doesn't make a lot of sense, but we need some mechanism
  //       to switch CSS classes based on some condition ;-)
  //       Possibly use OGNL for this?: ~index%2!=0 ? "blue" : "red"
  // TODO: at least the WOQualifierCondition thing should be moved to the parser
  //       level
  
  let tagName        : WOAssociation?
  let omitTags       : WOAssociation?
  let coreAttributes : WOElement?
  let extraAttributePlusConditions  : Bindings?
  let extraAttributeMinusConditions : Bindings?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    tagName  = bindings.removeValue(forKey: "tagName")
    omitTags = bindings.removeValue(forKey: "omitTags")
    
    coreAttributes =
      WOHTMLElementAttributes.buildIfNecessary(name: name + "_core",
                                               bindings: &bindings)
    
    extraAttributePlusConditions =
      WOGenericElement.extractAttributeConditions(from: &bindings, with: "+")
    extraAttributeMinusConditions =
      WOGenericElement.extractAttributeConditions(from: &bindings, with: "-")
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  static func extractAttributeConditions(from bindings : inout Bindings,
                                         with prefix   : String) -> Bindings?
  {
    var collected = Bindings()
    
    for ( key, assoc ) in bindings {
      guard key.hasPrefix(prefix) else { continue }
      
      bindings.removeValue(forKey: key)

      #if false // TODO
        /* Dirty hack, treat constant string and EOQualifier values as
         * EOQualifierAssociations ...
         * Would be better to deal with that at the parser level.
         */
        if assoc.isValueConstant, let v = assoc.value(in: nil) {
          if let s = v as? String {
            assoc = WOQualifierAssociation(s)
          }
          else if let q = v as? EOQualifier { /* very unlikely */
            assoc = WOQualifierAssociation(q)
          }
        }
      #endif
      
      let newKey =
        key[key.startIndex..<key.index(key.startIndex, offsetBy: prefix.count)]
      
      collected[String(newKey)] = assoc
    }
    
    return collected.isEmpty ? nil : collected
  }

  
  // MARK: - Generate Response
  
  override func appendExtraAttributes(to     response : WOResponse,
                                      in      context : WOContext,
                                      patternObject o : Any? = nil) throws
  {
    guard let extra = extra else { return }
    
    if extraAttributePlusConditions == nil &&
       extraAttributeMinusConditions == nil
    {
      try super.appendExtraAttributes(to: response, in: context,
                                      patternObject: o)
      return
    }
    
    /* complex variant, consider per-attribute conditions */
    let cursor = context.cursor
    
    for ( key, assoc ) in extra {
      /* check whether this attribute has a condition attached */
      var isPositive = true
      var condition = extraAttributePlusConditions?[key]
      if condition == nil {
        condition = extraAttributeMinusConditions?[key]
        if condition != nil { isPositive = false }
      }
      
      /* check whether the condition is true */
      if let condition = condition {
        let flag = condition.boolValue(in: cursor)
        if isPositive { if !flag  { continue } }
        else          { if  flag  { continue } }
      }
      
      /* add attribute */
      let v = assoc.stringValue(in: cursor)
      try response.appendAttribute(key, v)
    }
  }
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    if omitTags?.boolValue(in: cursor) ?? false { return }

    guard let tag = tagName?.stringValue(in: cursor) else { return }
    
    try response.appendBeginTag(tag)
    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    
    try response.appendBeginTagClose(context.closeAllElements)
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "tagName",  tagName,
      "omitTags", omitTags
    )
    
    if let extra = extra, !extra.isEmpty {
      ms += " attrs="
      ms += extra.keys.joined(separator: ",")
    }
    
    if extraAttributePlusConditions  != nil { ms += " has+" }
    if extraAttributeMinusConditions != nil { ms += " has-" }
  }
}
