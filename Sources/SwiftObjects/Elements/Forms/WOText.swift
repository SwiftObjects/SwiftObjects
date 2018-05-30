//
//  WOText.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Create HTML form textfields.
 *
 * Sample:
 * ```
 * Comment: WOText {
 *   name  = "comment";
 *   value = comment;
 * }
 * ```
 *
 * Renders:
 * ```
 *   <textarea name="firstname" value="abc" />
 * ```
 *
 * Bindings (WOInput):
 * ```
 *   id       [in] - string
 *   name     [in] - string
 *   value    [io] - object
 *   disabled [in] - boolean
 * ```
 * Bindings:<pre>
 * ```
 *   rows     [in] - int
 *   cols     [in] - int
 * ```
 *
 * Bindings (WOHTMLElementAttributes):<pre>
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg <input style="color:red;">)
 *   .key   [in]  - 'class' parameters (eg <input class="selected">)
 * ```
 */
open class WOText : WOInput {
  
  let rows : WOAssociation?
  let cols : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    rows = bindings.removeValue(forKey: "readonly")
    cols = bindings.removeValue(forKey: "cols")
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  override open func parseFormValue(_ value: Any?, in context: WOContext) throws
                     -> Any?
  {
    return value
  }
  
  open func formValue(for value: Any?, in context: WOContext) -> String? {
    guard let value = value else { return nil }
    return (value as? String) ?? String(describing: value)
  }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    
    try response.appendBeginTag("textarea");
    
    if let lid = id?.stringValue(in: cursor) {
      try response.appendAttribute("id", lid)
    }
    try response.appendAttribute("name", elementName(in: context))
    
    if let value = rows?.intValue(in: cursor), value > 0 {
      try response.appendAttribute("rows", value)
    }
    if let value = cols?.intValue(in: cursor), value > 0 {
      try response.appendAttribute("cols", value)
    }
    
    if disabled?.boolValue(in: cursor) ?? false {
      let value = context.generateEmptyAttributes ? nil : "disabled"
      try response.appendAttribute("disabled", value)
    }
    
    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagEnd()
    
    /* content */
    
    if let readValue = readValue,
       let s = formValue(for: readValue.value(in: cursor), in: context)
    {
      try response.appendContentHTMLString(s)
    }
    
    /* close tag */
    
    try response.appendEndTag("textarea");
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "rows", rows,
      "cols", cols
    )
  }
}
