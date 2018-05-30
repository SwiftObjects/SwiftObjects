//
//  WOResetButton.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Create HTML form reset button (input type=reset).
 *
 * Sample:
 *
 *     Firstname: WOResetButton {
 *         name  = "reset";
 *         value = "Reset";
 *     }
 *
 * Renders:
 * ```
 *   <input type="reset" name="reset" value="Reset" />
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
open class WOResetButton : WOInput {
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    
    try response.appendBeginTag("input")
    try response.appendAttribute("type", "reset")
    
    if let lid = id?.stringValue(in: cursor) {
      try response.appendAttribute("id", lid)
    }
    
    try response.appendAttribute("name", elementName(in: context))
    
    if let s = readValue?.stringValue(in: cursor) {
      try response.appendAttribute("value", s)
    }
    
    if disabled?.boolValue(in: cursor) ?? false {
      try response.appendAttribute("disabled",
                     context.generateEmptyAttributes ? nil : "disabled")
    }
    
    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagClose(context.closeAllElements)
  }
}
