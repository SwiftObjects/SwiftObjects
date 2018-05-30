//
//  WOImage.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * This element renders an <img> tag, possibly pointing to dynamically
 * generated URLs.
 *
 * Sample:
 *
 *     Banner: WOImage {
 *         src    = "/images/banner.gif";
 *         border = 0;
 *     }
 *
 * Renders:
 *
 *     <img src="/images/banner.gif" border="0" />
 *
 * Bindings (WOLinkGenerator for image resource):
 * ```
 *   src              [in] - string
 *   filename         [in] - string
 *   framework        [in] - string
 *   actionClass      [in] - string
 *   directActionName [in] - string
 *   queryDictionary  [in] - Map<String,String>
 *   ?wosid           [in] - boolean (constant!)
 *   - all bindings starting with a ? are stored as query parameters.
 * ```
 *
 * Regular bindings:
 * ```
 *   disableOnMissingLink [in] - boolean
 * ```
 */
open class WOImage : WOHTMLDynamicElement {
  // TBD: support 'data' binding URLs (also needs mimeType and should have 'key'
  //      bindings). Also: WOResourceManager.flushDataCache().
  //      I think this generates the data and puts it into the
  //      WOResourceManager. If it can't find the RM data, it most likely needs
  //      to regenerate it using an *action* (technically 'data' is the same
  //      like using 'action'?! [+ caching]).
  
  let link                 : WOLinkGenerator?
  let disabled             : WOAssociation?
  let disableOnMissingLink : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    disabled             = bindings.removeValue(forKey: "disabled")
    disableOnMissingLink = bindings.removeValue(forKey: "disableOnMissingLink")
    
    link = WOLinkGenerator.resourceLinkGenerator(keyedOn: "src", for: &bindings)
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    
    if disabled?.boolValue(in: cursor) ?? false { return }
    
    let url = link?.fullHref(in: context)
    if url == nil && (disableOnMissingLink?.boolValue(in: cursor) ?? false) {
      return
    }
    
    try response.appendBeginTag("img")
    if let url = url { try response.appendAttribute("src", url) }
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagClose(context.closeAllElements)
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if let link = link { ms += " src=\(link)" }
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "disabled",             disabled,
      "disableOnMissingLink", disableOnMissingLink
    )
  }
}

