//
//  WOSearchField.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * Create HTML form textfields which Safari renders as
 * search type textfields.
 *
 * Sample:
 *
 *     Searchfield: WOSearchField {
 *       name  = "searchfield";
 *       value = searchText;
 *     }
 *
 * Renders:
 * ```
 * <input type="search" name="searchfield" value="Go" />
 * ```
 *
 * Bindings (WOInput):
 * ```
 *   id       [in] - string
 *   name     [in] - string
 *   value    [io] - object
 *   disabled [in] - boolean
 * ```
 * Bindings (WOTextField):
 * ```
 *   size     [in] - int
 * ```
 * Bindings:
 * ```
 *   isIncremental [in] - bool
 *   placeholder   [in] - string
 *   autosaveName  [in] - string
 *   resultCount   [in] - int
 * ```
 * Bindings (WOHTMLElementAttributes):
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg <input style="color:red;">)
 *   .key   [in]  - 'class' parameters (eg <input class="selected">)
 * ```
 */
open class WOSearchField : WOTextField {
  
  let incremental : WOAssociation?
  let placeholder : WOAssociation?
  let autosave    : WOAssociation?
  let results     : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    incremental = bindings.removeValue(forKey: "incremental")
    placeholder = bindings.removeValue(forKey: "placeholder")
    autosave    = bindings.removeValue(forKey: "autosave")
    results     = bindings.removeValue(forKey: "results")
    
    super.init(name: name, bindings: &bindings, template: template)
  }

  override open var inputType: String { return "search" }
  
  override open func appendExtraAttributes(to response: WOResponse,
                                           in context: WOContext,
                                           patternObject o: Any?) throws
  {
    try super.appendExtraAttributes(to: response, in: context, patternObject: o)
    
    let cursor = context.cursor
    
    if incremental?.boolValue(in: cursor) ?? false {
      let value = context.generateEmptyAttributes ? nil : "incremental"
      try response.appendAttribute("incremental", value)
    }
    if let value = placeholder?.stringValue(in: cursor) {
      try response.appendAttribute("placeholder", value)
    }
    if let value = autosave?.stringValue(in: cursor) {
      try response.appendAttribute("autosave", value)
    }
    if let value = results?.intValue(in: cursor), value > 0 {
      try response.appendAttribute("results", value)
    }
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "incremental", incremental,
      "placeholder",    placeholder,
      "autosave",     autosave,
      "results",     results
    )
  }
}
