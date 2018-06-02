//
//  WOPasswordField.swift
//  SwiftObjects
//
//  Created by Helge Hess on 02.06.18.
//

/**
 * Create HTML form password fields. Remember that such are only secure over
 * secured connections (e.g. SSL).
 *
 * Sample:
 * ```
 * Firstname: WOPasswordField {
 *   name  = "password";
 *   value = password;
 * }
 * ```
 *
 * Renders:
 * ```
 *   <input type="password" name="password" value="abc123" />
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
 * Bindings:<pre>
 * ```
 *   size       [in]  - int
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
open class WOPasswordField : WOInput {
  
  let size : WOAssociation?
  
  open var inputType : String { return "text" }
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    size = bindings.removeValue(forKey: "size")
    super.init(name: name, bindings: &bindings, template: template)
  }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    
    try response.appendBeginTag("input");
    try response.appendAttribute("type", "password")
    
    if let lid = id?.stringValue(in: cursor) {
      try response.appendAttribute("id", lid)
    }
    try response.appendAttribute("name", elementName(in: context))
    
    if let s = readValue?.stringValue(in: cursor) {
      // TBD: do we really want this?
      try response.appendAttribute("value", s)
      context.log.warn("WOPasswordField is delivering a value",
                       "(consider writeValue)", self)
    }
    
    if let size = size {
      let i = size.intValue(in: cursor)
      if i > 0 { try response.appendAttribute("size", i) }
    }
    
    if disabled?.boolValue(in: cursor) ?? false {
      let value = context.generateEmptyAttributes ? nil : "disabled"
      try response.appendAttribute("disabled", value)
    }
    
    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    
    try response.appendBeginTagClose(context.closeAllElements)
  }
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WOString.appendBindingToDescription(&ms, "size", size)
  }
}
