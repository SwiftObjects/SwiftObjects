//
//  WOTextField.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import struct Foundation.CharacterSet

/**
 * Create HTML form textfields.
 *
 * Sample:
 *
 *     Firstname: WOTextField {
 *         name  = "firstname";
 *         value = firstname;
 *     }
 *
 * Renders:
 * ```
 *   <input type="text" name="firstname" value="Donald" />
 * ```
 *
 * Bindings (WOInput):
 * ```
 *   id             [in]  - string
 *   name           [in]  - string
 *   value          [io]  - object
 *   readValue      [in]  - object (different value for generation)
 *   writeValue     [out] - object (different value for takeValues)
 *   disabled       [in]  - boolean
 *   idname         [in]  - string   - set id and name bindings in one step</pre>
 * ```
 * Bindings (WOTextField):
 * ```
 *   readonly       [in]  - boolean
 *   size           [in]  - int
 *   trim           [in]  - boolean
 *   errorItem      [out] - WOErrorItem
 * ```
 * Bindings (WOFormatter):
 * ```
 *   calformat      [in]  - a dateformat   (returns java.util.Calendar)
 *   dateformat     [in]  - a dateformat   (returns java.util.Date)
 *   lenient        [in]  - bool, only in combination with cal/dateformat!
 *   numberformat   [in]  - a numberformat (NumberFormat.getInstance())
 *   currencyformat [in]  - a numberformat (NumberFormat.getCurrencyInstance())
 *   percentformat  [in]  - a numberformat (NumberFormat.getPercentInstance())
 *   intformat      [in]  - a numberformat (NumberFormat.getIntegerInstance())
 *   formatterClass [in]  - Class or class name of a formatter to use
 *   formatter      [in]  - java.text.Format used to format the value or the
 *                          format for the formatterClass
 * ```
 * Bindings (WOHTMLElementAttributes):
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg &lt;input style="color:red;"&gt;)
 *   .key   [in]  - 'class' parameters (eg &lt;input class="selected"&gt;)
 * ```
 */
open class WOTextField : WOInput {
  
  let readonly  : WOAssociation?
  let size      : WOAssociation?
  let trim      : WOAssociation?
  let errorItem : WOAssociation?
  let formatter : WOFormatter?
  
  open var inputType : String { return "text" }
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    readonly  = bindings.removeValue(forKey: "readonly")
    size      = bindings.removeValue(forKey: "size")
    trim      = bindings.removeValue(forKey: "trim")
    errorItem = bindings.removeValue(forKey: "errorItem")
    formatter = WOFormatterFactory.formatter(for: &bindings)
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  override open func parseFormValue(_ value: Any?, in context: WOContext) throws
                     -> Any?
  {
    guard let v = value else { return nil }
    if !(value is String) && formatter == nil { return value }
    
    let s : String = {
      let s = UObject.stringValue(v)
      let doTrim = trim?.boolValue(in: context.cursor) ?? false
      return doTrim ? s.trimmingCharacters(in: CharacterSet.whitespaces) : s
    }()
    
    return try formatter?.objectValue(for: s, in: context) ?? s
  }
  
  open func formValue(for value: Any?, in context: WOContext) -> String? {
    guard let formatter = formatter else {
      guard let value = value else { return nil }
      return UObject.stringValue(value)
    }
    return formatter.string(for: value, in: context)
  }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    let lid    = id?.stringValue(in: cursor)
    let n      = elementName(in: context)
    var error  : WOErrorReport.WOErrorItem? = nil
    
    /* determine error item, we need this to render the b0rked value! */
    
    if let er = context.errorReport {
      // TBD: lid is NOT the elementID! and we do not check the 'id' in
      //      takevalues, BUT we might consolidate both IDs in one? ('id'
      //      HTML value and the elementID, both are unique)
      if let lid = lid { error = er.errorForElementID(lid) }
      if error == nil  { error = er.errorForName(n) }
    }
    
    /* push error item, if there is one for the element */
    
    try? errorItem?.setValue(error, in: cursor)

    /* calculate the form value to render, can be the error value! */
    
    let sv : String?
    
    if let error = error {
      let ov = error.value
      sv = (ov as? String) ?? formValue(for: ov, in: context)
    }
    else if let readValue = readValue {
      /* retrieve value from controller, and format it for output */
      let ov = readValue.value(in: cursor)
      sv = formValue(for: ov, in: context)
    }
    else {
      sv = nil
    }

    /* begin rendering */
    
    try response.appendBeginTag("input");
    try response.appendAttribute("type", inputType)
    
    if let lid = lid { try response.appendAttribute("id", lid) }
    try response.appendAttribute("name", n)
    
    if readValue != nil, let sv = sv { // TBD: only render with a binding?
      try response.appendAttribute("value", sv)
    }
    
    if let size = size {
      let i = size.intValue(in: cursor)
      if i > 0 { try response.appendAttribute("size", i) }
    }
    
    if disabled?.boolValue(in: cursor) ?? false {
      let value = context.generateEmptyAttributes ? nil : "disabled"
      try response.appendAttribute("disabled", value)
    }
    if readonly?.boolValue(in: cursor) ?? false {
      let value = context.generateEmptyAttributes ? nil : "readonly"
      try response.appendAttribute("readonly", value)
    }
    
    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    
    try response.appendBeginTagClose(context.closeAllElements)
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "readonly",  readonly,
      "size",      size,
      "trim",      trim,
      "errorItem", errorItem
    )
  }
}
