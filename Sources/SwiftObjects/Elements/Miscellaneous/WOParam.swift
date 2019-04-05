//
//  WOParam.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

/**
 * Parameter value for applets.
 *
 * Bindings (WOLinkGenerator for image resource):
 * ```
 *   name  [in] - string
 *   value [in] - string
 * ```
 */
public class WOParam : WOHTMLDynamicElement {
  // TODO: document
  // TODO: WO also allows for an 'action' binding. Not sure whethers thats
  //       useful.
  
  let name  : WOAssociation?
  let value : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    self.name  = bindings.removeValue(forKey: "name")
    self.value = bindings.removeValue(forKey: "value")

    super.init(name: name, bindings: &bindings, template: template)
  }
  
  // MARK: - Response Generation

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    let cursor = context.cursor
    
    try response.appendBeginTag("param")
    
    if let a = name {
      try response.appendAttribute("name", a.stringValue(in: cursor))
    }
    if let a = value {
      try response.appendAttribute("value", a.stringValue(in: cursor))
    }
    
    try appendExtraAttributes(to: response, in: context)
    if context.closeAllElements {
      try response.appendBeginTagClose()
    }
    else {
      try response.appendBeginTagEnd()
    }
  }
}
