//
//  WORadioButton.swift
//  SwiftObjects
//
//  Created by Helge Hess on 02.06.18.
//

/**
 * Create HTML form radio buttons.
 *
 * Sample:
 * ```
 * Firstname: WORadioButton {
 *   name      = "products";
 *   value     = "iPhone";
 *   selection = selectedProduct;
 * }
 * ```
 *
 * Renders:
 * ```
 *   <input type="radio" name="products" value="iPhone" />
 * ```
 *
 * Bindings (WOInput):<pre>
 * ```
 *   id         [in]  - string
 *   name       [in]  - string
 *   value      [io]  - object
 *   readValue  [in]  - object (different value for generation)
 *   writeValue [out] - object (different value for takeValues)
 *   disabled   [in]  - boolean</pre>
 * ```
 * Bindings:<pre>
 * ```
 *   selection [io] - object
 *   checked   [io] - boolean</pre>
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
open class WORadioButton : WOInput {
  
  let selection : WOAssociation?
  let checked   : WOAssociation?

  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    selection = bindings.removeValue(forKey: "selection")
    checked   = bindings.removeValue(forKey: "checked")
    super.init(name: name, bindings: &bindings, template: template)
  }

  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    let cursor = context.cursor
    let log    = context.log

    if let a = disabled, a.boolValue(in: cursor) { return }

    let formName = elementName(in: context)
    guard let formValue = request.stringFormValue(for: formName) else {
      /* radio buttons are special, they are selected based upon there value */
      log.trace("got not form value for radio button elem:", formName)
      return
    }
    
    guard let readValue = readValue else {
      // nothing to push to (TBD: couldn't that be write?)
      log.error("missing value binding for element:", self)
      return
    }
    
    let v  = readValue.value(in: cursor)
    let vs = UObject.stringValue(v)
    
    /* check whether we are the selected radio button */
    guard formValue == vs else {
      /* ok, was a different element (with the same form name) */
      
      /*
       * Note: we set the checked binding to false which implies that the
       *       checked bindings of the radio buttons MUST bind to different
       *       variables! Otherwise they will overwrite each other!
       */
      if checked?.isValueSettableInComponent(cursor) ?? false {
        try checked?.setBoolValue(false, in: cursor)
      }
      return
    }

    /* yup, we are the selected radio button, fill the bindings */
    if checked?.isValueSettableInComponent(cursor) ?? false {
      try checked?.setBoolValue(true, in: cursor)
    }
    if selection?.isValueSettableInComponent(cursor) ?? false {
      try selection?.setValue(v, in: cursor)
    }
  }

  
  // MARK: - Generate Response
  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    guard !context.isRenderingDisabled else { return }
    
    let cursor   = context.cursor
    let log      = context.log
    let formName = elementName(in: context)
    
    guard let readValue = readValue else {
      try response.appendContentString("[ERROR: radio w/o value binding]")
      return
    }
    
    let v  = readValue.value(in: cursor)
    let vs = UObject.stringValue(v)
    
    try response.appendBeginTag("input")
    try response.appendAttribute("type", "radio")
    
    if let lid = id?.stringValue(in: cursor) {
      try response.appendAttribute("id", lid)
    }
    try response.appendAttribute("name",  formName)
    try response.appendAttribute("value", vs)
    if disabled?.boolValue(in: cursor) ?? false {
      let value = context.generateEmptyAttributes ? nil : "disabled"
      try response.appendAttribute("disabled", value)
    }

    /* Note: the 'checked' binding has precedence, but its better to use either
     *       'checked' _or_ 'selection'.
     */
    if let checked = checked {
      if checked.boolValue(in: cursor) {
        try response.appendAttribute("checked",
                       context.generateEmptyAttributes ? nil : "checked")
      }
    }
    else if let selection = selection {
      /* compare selection with value */
      let s = selection.value(in: cursor)
      if UObject.isEqual(v, s) {
        try response.appendAttribute("checked",
                       context.generateEmptyAttributes ? nil : "checked")
      }
    }
    else {
      /* if the button isn't handled by the page but by some DirectAction or
       * other script, it is not an error not to have those bindings
       */
      log.info("no selection or checked binding set for radio button");
    }

    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    
    try response.appendBeginTagClose(context.closeAllElements)
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "selection", selection,
      "checked",   checked
    )
  }
}
