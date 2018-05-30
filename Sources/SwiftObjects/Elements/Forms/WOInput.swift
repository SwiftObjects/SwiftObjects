//
//  WOInput.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Abstract superclass for elements which participate in FORM processing.
 *
 * Bindings:
 * ```
 *   id         [in]  - string
 *   name       [in]  - string
 *   value      [io]  - object
 *   readValue  [in]  - object (different value for generation)
 *   writeValue [out] - object (different value for takeValues)
 *   disabled   [in]  - boolean
 *   idname     [in]  - string   - set id and name bindings in one step
 * ```
 * Bindings (WOHTMLElementAttributes):
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg `<input style="color:red;">`)
 *   .key   [in]  - 'class' parameters (eg `<input class="selected">`)
 * ```
 */
open class WOInput : WOHTMLDynamicElement {
  
  let id             : WOAssociation?
  let name           : WOAssociation?
  let readValue      : WOAssociation?
  let writeValue     : WOAssociation?
  let disabled       : WOAssociation?
  let coreAttributes : WOElement?

  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    id         = bindings.removeValue(forKey: "id")
    disabled   = bindings.removeValue(forKey: "disabled")
    
    let value  = bindings.removeValue(forKey: "value")
    readValue  = bindings.removeValue(forKey: "readValue")  ?? value
    writeValue = bindings.removeValue(forKey: "writeValue") ?? value
    
    /* type is defined by the element itself ... */
    _ = bindings.removeValue(forKey: "type")
    
    var fname  = bindings.removeValue(forKey: "name")
    if let idName = bindings.removeValue(forKey: "idname") {
      if fname == nil { fname = idName }
      
      if bindings["id"] == nil {
        bindings["id"] = idName
      }
    }
    
    self.name = fname
    
    coreAttributes = WOHTMLElementAttributes
      .buildIfNecessary(name: name + "_core", bindings: &bindings)
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  /**
   * Checks whether the name binding is set. If so, the name is returned. If
   * not, the current element-id is returned.
   *
   * @param _ctx - the WOContext to operate in
   * @return a 'name' for the form element
   */
  func elementName(in context: WOContext) -> String {
    return name?.stringValue(in: context.cursor) ?? context.elementID
  }

  
  // MARK: - Taking Form Values
  
  /**
   * This method is called by takeValuesFromRequest() to convert the given
   * value to the internal representation. Which is usually done by a
   * WOFormatter subclass.
   *
   * If the method throws an exception, handleParseException() will get called
   * to deal with it. The default implementation either adds the error to an
   * WOErrorReport, or throws the exception as a runtime exception.
   */
  open func parseFormValue(_ value: Any?, in context: WOContext) throws -> Any?
  {
    /* redefined in subclasses */
    return value;
  }
  
  /**
   * This method is called if a format could not parse the input value (usually
   * a String). For example a user entered some string in a textfield which has
   * a numberformat attached.
   *
   * @param _formName  - name of the form field
   * @param _formValue - value transmitted by the browser
   * @param _e         - the exception which was caught (ParseException)
   * @param _ctx       - the WOContext
   * @return true if the caller should stop processing
   */
  open func handleParseError(inField formName: String,
                             with formValue: Any?,
                             error: Error, in context: WOContext) throws
  {
    if let report = context.errorReport {
      return report.addError(name: formName, error: error, value: formValue)
    }
    
    if let page = context.component {
      return page.validationFailed(with: error, value: formValue,
                                   keyPath: writeValue?.keyPath)
    }
    
    // TODO: add to some 'error report' object?
    context.log.warn("failed to parse form value with Format:",
                     formValue, error)
    throw error
  }
  
  open func handleSetValueError(cursor: Any?, assocation: WOAssociation?,
                                inField formName: String,
                                with    formValue: Any?,
                                error: Error, in context: WOContext) throws
  {
    context.log.warn("failed to push form value to object:", formValue, error)
    
    if let report = context.errorReport {
      report.addError(name: formName, error: error, value: formValue)
      return
    }
    
    if let page = context.component {
      return page.validationFailed(with: error, value: formValue,
                                   keyPath: writeValue?.keyPath)
    }
    
    throw error
  }
  
  
  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    let cursor = context.cursor
    
    if let a = disabled, a.boolValue(in: cursor) { return }
    
    guard let writeValue = writeValue else { /* nothing to push to */
      context.log.info("missing value binding for element:", self)
      return
    }
    guard writeValue.isValueSettableInComponent(cursor) else {
      context.log.info("value binding cannot be set for element:", self)
      return
    }
    
    let formName  = elementName(in: context)
    var formValue = request.formValue(for: formName)
    
    if formValue == nil, let r = formName.range(of: ":") {
      /*
       * Handle form values which got processed by Zope converters, eg
       *
       *   uid:int
       *
       * The suffix will get stripped from the form name when the request is
       * processed initially.
       */
      let n = formName[formName.startIndex..<r.lowerBound]
      formValue = request.formValue(for: String(n))
    }
    
    if formValue == nil {
      /* This one is tricky
       *
       * It only pushes values if the request actually specified a value
       * for this field. For example if you have a WOTextField with name
       * 'q', this will push a value to the field:
       *   /Page/default?q=abc
       * but this won't:
       *   /Page/default
       * To push an empty value, you need to use
       *   /Page/default?q=
       *
       * TODO: does just q work as well? (/abc?q)
       */
      /* Note: HTML checkboxes do NOT submit values when they are not checked,
       *       so they need special handling. Otherwise you won't be able
       *       to "uncheck" a checkbox. This is implemented in WOCheckBox.
       */
      return
    }
    
    do {
      formValue = try parseFormValue(formValue, in: context)
    }
    catch {
      try handleParseError(inField: formName, with: formValue, error: error,
                           in: context)
    }
    
    do {
      try writeValue.setValue(formValue, in: cursor)
    }
    catch {
      try handleSetValueError(cursor: cursor, assocation: writeValue,
                              inField: formName, with: formValue,
                              error: error, in: context)
    }
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if id === name {
      WOString.appendBindingToDescription(&ms, "idname", id)
    }
    else {
      WOString.appendBindingsToDescription(&ms, "id", id, "name", name)
    }
    
    if readValue === writeValue {
      WOString.appendBindingToDescription(&ms, "value", readValue)
    }
    else {
      WOString.appendBindingsToDescription(&ms,
        "readValue", readValue, "writeValue", writeValue
      )
    }
  }
}
