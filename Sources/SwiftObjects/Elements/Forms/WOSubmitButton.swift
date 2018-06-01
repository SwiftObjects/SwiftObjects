//
//  WOSubmitButton.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Generates an HTML form submit button.
 *
 * Sample:
 *
 *     OK: WOSubmitButton {
 *         name  = "OK";
 *         value = "OK";
 *     }
 *
 * Renders:
 * ```
 * <input type="submit" name="OK" value="OK" />
 * ```
 *
 * Bindings (WOInput):
 * ```
 *   id       [in] - string
 *   name     [in] - string
 *   value    [io] - object
 *   disabled [in] - boolean
 * ```
 * Bindings:
 * ```
 *   action   [in] - action
 *   pageName [in] - string
 * ```
 * Bindings (WOHTMLElementAttributes):
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg <input style="color:red;">)
 *   .key   [in]  - 'class' parameters (eg <input class="selected">)
 * ```
 */
open class WOSubmitButton : WOInput {
  
  let action   : WOAssociation?
  let pageName : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    pageName   = bindings.removeValue(forKey: "pageName")
    let action = bindings.removeValue(forKey: "action")
    
    /* special, shortcut hack. Doesn't make sense to have String actions ... */
    if let a = action, a.isValueConstant, let v = a.value(in: nil) as? String {
      self.action = WOAssociationFactory.associationWithKeyPath(v)
    }
    else {
      self.action = action
    }
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  
  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    let cursor = context.cursor
    if disabled?.boolValue(in: cursor) ?? false { return }
    
    let formValue = request.formValue(for: elementName(in: context))
    
    if let a = writeValue, a.isValueSettableInComponent(cursor) {
      try a.setValue(formValue, in: cursor)
    }
    
    if formValue != nil, action != nil || pageName != nil {
      context.addActiveFormElement(self)
    }
  }
  
  override open func invokeAction(for request : WORequest,
                                  in  context : WOContext) throws -> Any?
  {
    let cursor = context.cursor
    if disabled?.boolValue(in: cursor) ?? false { return nil }
    
    var lid = context.elementID
    let v   = id?.value(in: cursor)
    
    if v is Bool {} /* in this mode we just expose the ID in HTML */
    else if let v = v {
      lid = (v as? String) ?? String(describing: v)
    }
    
    let result : Any? = {
      guard lid == context.senderID else { return nil }
      if let a = action   { return a.value(in: cursor) }
      if let a = pageName {
        guard let pname = a.stringValue(in: cursor) else { return nil }
        return context.application.pageWithName(pname, in: context)
      }
      return nil
    }()
    
    return result
  }
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    
    try response.appendBeginTag("input")
    try response.appendAttribute("type", "submit")
    
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
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "action",   action,
      "pageName", pageName
    )
  }
}
