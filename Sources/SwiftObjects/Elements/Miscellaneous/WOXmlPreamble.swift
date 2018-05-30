//
//  WOXmlPreamble.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * Used to generate the `<?xml?>` preamble and to configure
 * proper content coders for the used response.
 *
 * Sample:
 *
 *     <#WOXmlPreamble></#WOXmlPreamble>
 *
 * Renders:
 *
 *     <?xml version="1.0" encoding="UTF-8"?>
 *
 * Bindings:
 * ```
 *   version    [in] - string (default: "1.0")
 *   encoding   [in] - IANA charset to use, i.e. "UTF-8"
 *   standalone [in] - bool (default: empty)
 * ```
 */
public class WOXmlPreamble : WOHTMLDynamicElement {
  
  static let versionAssoc  = WOAssociationFactory.associationWithValue("1.0")
  static let encodingAssoc = WOAssociationFactory.associationWithValue("UTF-8")
  
  let version    : WOAssociation
  let encoding   : WOAssociation
  let standalone : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    version  = bindings.removeValue(forKey: "version")
            ?? WOXmlPreamble.versionAssoc
    encoding = bindings.removeValue(forKey: "encoding")
            ?? WOXmlPreamble.encodingAssoc
    standalone = bindings.removeValue(forKey: "standalone")

    super.init(name: name, bindings: &bindings, template: template)
  }
  
  /* response generation */
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    // TODO:
    //_r.setTextCoder(NSXmlEntityTextCoder.sharedCoder,
    //                NSHtmlAttributeEntityTextCoder.sharedCoder);
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    
    /* render tag */
    
    try response.appendBeginTag("?xml")
    
    if let s = version.stringValue(in: cursor), !s.isEmpty {
      try response.appendAttribute("version", s)
    }
    if let s = encoding.stringValue(in: cursor), !s.isEmpty {
      try response.appendAttribute("encoding", s)
    }

    if let standalone = standalone {
      let tf = standalone.boolValue(in: cursor)
      try response.appendAttribute("standalone", tf ? "yes" : "no")
    }
    
    try appendExtraAttributes(to: response, in: context)
    try response.appendContentCharacter("?")
    try response.appendBeginTagEnd()
  }
}
