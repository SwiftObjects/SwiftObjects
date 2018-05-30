//
//  WOCheckBox.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Create HTML form checkbox field.
 *
 * Checkboxes are different to other form elements in the request handling.
 * Regular form elements always send a value when being submitted. Checkboxes
 * only do so if they are checked.<br>
 * So we cannot distinguish between a checkbox not being submitted and a
 * checkbox being disabled :-/
 *
 * To fix the issue we also render a hidden form field which is always
 * submitted. If this is not required, it can be turned off with the 'safeGuard'
 * binding.
 *
 * Sample:
 *
 *     IsAdmin: WOCheckBox {
 *         name    = "isadmin";
 *         checked = account.isAdmin;
 *     }
 *
 * Renders:
 * ```
 *   <input type="hidden"   name="isadmin_sg" value="1" />
 *   <input type="checkbox" name="isadmin"    value="1" />
 * ```
 *
 * Bindings:
 * ```
 *   selection [io] - object / Collection
 *   checked   [io] - boolean
 *   safeGuard [in] - boolean (def: true, submit unchecked state)
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
open class WOCheckBox : WOInput {
  // TBD: should we support a label? (<label for=id>label</label>)
  // FIXME: Swift doesn't support the selection thing yet (to support checkbox
  //        groups)

  let selection : WOAssociation?
  let checked   : WOAssociation?
  let safeGuard : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    selection = bindings.removeValue(forKey: "selection")
    checked   = bindings.removeValue(forKey: "checked")
    safeGuard = bindings.removeValue(forKey: "safeGuard")
    
    super.init(name: name, bindings: &bindings, template: template)
  }

  
  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    /*
     * Checkboxes are special in their form-value handling. If the form is
     * submitted and the checkbox is checked, a 'YES' value is transferred in
     * the request.
     * BUT: If the checkbox is not-checked, no value is transferred at all!
     *
     * TODO: this one is really tricky because we don't know whether the
     *       takeValues is actually triggered by a request which represents the
     *       form that contains the checkbox!
     *       Best workaround for now is to run takeValues only for POST.
     */
    let cursor = context.cursor
    if disabled?.boolValue(in: cursor) ?? false { return }
    
    let formName  = elementName(in: context)
    let formValue = request.formValue(for: formName)

    let doIt : Bool = {
      if safeGuard?.boolValue(in: cursor) ?? true {
        /* we are configured to have a safeguard, check whether its submitted */
        return request.formValue(for: formName + "_sg") != nil
      }
      return true
    }()
    
    let hasValue = formValue != nil
    if doIt, let a = checked, a.isValueSettableInComponent(cursor) {
      try a.setBoolValue(hasValue, in: cursor)
    }
    
    // TODO: document why we don't reset the value if missing
    if doIt && hasValue,
       let a = writeValue, a.isValueSettableInComponent(cursor)
    {
      try a.setValue(formValue, in: cursor)
    }
    
    if doIt, let selection = selection {
      let sel = selection.value(in: cursor)
      let rv  : Any? = {
        if let a = readValue { return a.value(in: cursor) }
        return formValue
      }()
      
      #if false // TODO: well, how to deal with that in Swift :-)
        if let sel = sel as? Collection {
          if formValue != nil { sel.append(rv) }
          else                { sel.remove(rv) }
        }
      #endif
      if doIt { /* push simple value */
        try selection.setValue(hasValue ? rv : nil, in: cursor)
      }
    }
  }
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }

    let cursor = context.cursor
    let cbname = elementName(in: context)
    
    try response.appendBeginTag("input")
    try response.appendAttribute("type", "checkbox")
    if let lid = id?.stringValue(in: cursor) {
      try response.appendAttribute("id", lid)
    }
    try response.appendAttribute("name", cbname)
    
    let v = readValue?.stringValue(in: cursor)
    try response.appendAttribute("value", v ?? "1")
    
    if disabled?.boolValue(in: cursor) ?? false {
      try response.appendAttribute("disabled",
                     context.generateEmptyAttributes ? nil : "disabled")
    }
    
    let isChecked : Bool = {
      if let a = checked { return a.boolValue(in: cursor) }
      if let a = selection {
        let o = a.value(in: cursor)
        // TODO: support Collections
        if let v = v, let o = o {
          // TODO: compare. How? :-)
          // FIXME: THIS IS CRAZY STUFF :-)
          // In ZeeQL we have a protocol for dynamic equality
          return String(describing: v) == String(describing: o)
        }
        else if v != nil || o != nil {
          return false
        }
        else {
          return true
        }
      }
      return false
    }()
    if isChecked {
      try response.appendAttribute("checked",
                     context.generateEmptyAttributes ? nil : "checked")
    }

    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagClose(context.closeAllElements)
    
    /* add safeguard field */
    try response.appendBeginTag("input")
    try response.appendAttribute("type", "hidden")
    try response.appendAttribute("name",  cbname + "_sg")
    try response.appendAttribute("value", cbname)
    try response.appendBeginTagClose(context.closeAllElements)
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "selection", selection,
      "checked",   checked,
      "safeGuard", safeGuard
    )
  }
}

