//
//  WOEntity.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * This element just renders a named or numeric entity in HTML/XML syntax.
 *
 * Sample:
 *
 *     AUml: WOEntity { name = "auml"; }
 *
 * Renders:
 * ```
 *   &auml;
 * ```
 *
 * Bindings:
 * ```
 *   name [in] - string
 * ```
 */
open class WOEntity : WOHTMLDynamicElement {
  
  let name : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    self.name = bindings.removeValue(forKey: "name")
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    guard let name = name?.stringValue(in: context.cursor), !name.isEmpty else {
      return
    }
    try response.appendContentCharacter("&")
    try response.appendContentString(name)
    try response.appendContentCharacter(";")
  }
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    WODynamicElement.appendBindingsToDescription(&ms, "name", name)
  }
}

