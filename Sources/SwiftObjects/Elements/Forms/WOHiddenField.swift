//
//  WOHiddenField.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Create HTML form hidden field.
 *
 * Sample:
 *
 *     Firstname: WOHiddenField {
 *         name  = "hideme";
 *         value = notAPassword;
 *     }
 *
 * Renders:
 * ```
 *   <input type="hidden" name="hideme" value="abc123" />
 * ```
 *
 * Bindings (WOInput):
 * ```
 *   id         [in]  - string
 *   name       [in]  - string
 *   value      [io]  - object
 *   readValue  [in]  - object (different value for generation)
 *   writeValue [out] - object (different value for takeValues)
 *   disabled   [in]  - boolean
 * ```
 *
 * Bindings (WOHTMLElementAttributes):
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg <input style="color:red;">)
 *   .key   [in]  - 'class' parameters (eg <input class="selected">)
 * ```
 */
open class WOHiddenField : WOInput {
  
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    if disabled?.boolValue(in: cursor) ?? false { return }
    
    try response.appendBeginTag("input",
                   "type", "hidden", "name", elementName(in: context))
    
    if let lid = id?.stringValue(in: cursor) {
      try response.appendAttribute("id", lid)
    }
    
    if let s = readValue?.stringValue(in: cursor) {
      try response.appendAttribute("value", s)
    }

    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    
    try response.appendBeginTagClose(context.closeAllElements)
  }
  
}
