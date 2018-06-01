//
//  WOPopUpButton.swift
//  SwiftObjects
//
//  Created by Helge Hess on 01.06.18.
//

import Foundation

/**
 * Create HTML form single-selection popups.
 *
 * Sample:
 * ```
 * Country: WOPopUpButton {
 *   name      = "country";
 *   list      = ( "UK", "US", "Germany" );
 *   item      = item;
 *   selection = selectedCountry;
 * }
 * ```
 * Renders:
 * ```
 *   <select name="country">
 *     <option value="UK">UK</option>
 *     <option value="US" selected>US</option>
 *     <option value="Germany">Germany</option>
 *     [sub-template]
 *   </select>
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
 * Bindings:
 * ```
 *   list              [in]  - List
 *   item              [out] - object
 *   selection         [out] - object
 *   string            [in]  - String
 *   noSelectionString [in]  - String
 *   selectedValue     [out] - String
 *   escapeHTML        [in]  - boolean
 *   itemGroup
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
open class WOPopUpButton : WOInput {
  
  static let WONoSelectionString = "WONoSelectionString"

  let list              : WOAssociation?
  let item              : WOAssociation?
  let selection         : WOAssociation?
  let string            : WOAssociation?
  let noSelectionString : WOAssociation?
  let selectedValue     : WOAssociation?
  let escapeHTML        : WOAssociation?
  let itemGroup         : WOAssociation?
  let formatter         : WOFormatter?
  let template          : WOElement?

  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    list               = bindings.removeValue(forKey: "list")
    item               = bindings.removeValue(forKey: "item")
    selection          = bindings.removeValue(forKey: "selection")
    string             = bindings.removeValue(forKey: "string")
    noSelectionString  = bindings.removeValue(forKey: "noSelectionString")
    selectedValue      = bindings.removeValue(forKey: "selectedValue")
    escapeHTML         = bindings.removeValue(forKey: "escapeHTML")
    itemGroup          = bindings.removeValue(forKey: "itemGroup")
    
    formatter = WOFormatterFactory.formatter(for: &bindings)
    
    self.template = template
    
    super.init(name: name, bindings: &bindings, template: template)
  }

  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    let cursor = context.cursor
    
    if let a = disabled, a.boolValue(in: cursor) { return }
    
    let formName = elementName(in: context)
    
    guard let formValue = request.stringFormValue(for: formName) else {
      /* We need to return here and NOT reset the selection. This is because the
       * page might have been invoked w/o a form POST! If we do not, this
       * resets the selection.
       *
       * TODO: check whether HTML forms MUST submit an empty form value for
       *       popups.
       */
      return;
    }

    let isNoSelection = formValue == WOPopUpButton.WONoSelectionString
    
    let objects : WOListWalkable.AnyCollectionIteratorInfo?
    if let list = list {
      objects = listForValue(list.value(in: cursor))?.listIterate()
    }
    else {
      objects = nil
    }
    
    var object : Any? = nil
    
    if let _ = writeValue {
      /* has a 'value' binding, walk list to find object */
      if let ( _, iterator ) = objects {
        let item : WOAssociation? = {
          guard let item = self.item else { return nil }
          return item.isValueSettableInComponent(cursor) ? item : nil
        }()
        
        for lItem in iterator {
          try item?.setValue(lItem, in: cursor)
          
          let cv = readValue?.stringValue(in: cursor)
          if cv == formValue {
            object = lItem
            break
          }
        }
      }
    }
    else if !isNoSelection {
      /* an index binding? */
      let idx = Int(formValue) ?? -1 // hmmm
      if let ( count, iterator ) = objects {
        if idx < 0 || idx >= count {
          context.log.error("popup value out of range:", idx, count, objects)
          object = nil
        }
        else {
          var p = 0
          for lItem in iterator { // sigh
            if p == idx {
              object = lItem
              break
            }
            p += 1
          }
        }
      }
    }
    else {
      context.log.warn("popup has no form value, value binding or selection:",
                       self, formValue)
    }

    /* push selected value */
    
    try selectedValue?.setValue(isNoSelection ? nil : formValue, in: cursor)
    
    /* process selection */
    
    if let a = selection, a.isValueSettableInComponent(cursor) {
      try a.setValue(object, in: cursor)
    }

    /* reset item to avoid dangling references */
    try item?.setValue(nil, in: cursor)
  }
  
  
  // TODO: rendering

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "list",              list,
      "item",              item,
      "selection",         selection,
      "string",            string,
      "noSelectionString", noSelectionString,
      "selectedValue",     selectedValue,
      "escapeHTML",        escapeHTML,
      "itemGroup",         itemGroup
    )
  }
}
