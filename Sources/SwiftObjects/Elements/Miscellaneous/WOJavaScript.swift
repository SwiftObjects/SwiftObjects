//
//  WOJavaScript.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * Generate a script tag containing JavaScript code or a link to JavaScript
 * code.
 *
 * Sample:
 *
 *     Script: WOJavaScript {
 *         filename = "myscript.js";
 *     }
 *
 * Renders:
 * ```
 *   <script type="text/javascript" language="JavaScript"
 *           src="/MyApp/wr/myscript.js"> </script>
 * ```
 *
 * Bindings:<pre>
 * ```
 *   scriptFile    [in] - string/File/URL (contents will be embedded)
 *   scriptString  [in] - string          (will be embedded)
 *   hideInComment [in] - bool
 *   escapeHTML    [in] - boolean (set to false to avoid HTML escaping)</pre>
 * ```
 *
 * Bindings (WOLinkGenerator for image resource):
 * ```
 *   scriptSource     [in] - string
 *   src              [in] - string (^ same like above)
 *   filename         [in] - string
 *   framework        [in] - string
 *   actionClass      [in] - string
 *   directActionName [in] - string
 *   queryDictionary  [in] - Dictionary<String, Any>
 *   ?wosid           [in] - boolean (constant!)
 *   - all bindings starting with a ? are stored as query parameters.
 * ```
 */
open class WOJavaScript : WOHTMLDynamicElement {
  
  let scriptSource  : WOLinkGenerator?
  let scriptFile    : WOAssociation?
  let scriptString  : WOAssociation?
  let hideInComment : WOAssociation?
  let escapeHTML    : WOAssociation?
  let template      : WOElement?

  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    scriptFile    = bindings.removeValue(forKey: "scriptFile")
    scriptString  = bindings.removeValue(forKey: "scriptString")
    hideInComment = bindings.removeValue(forKey: "hideInComment")
    escapeHTML    = bindings.removeValue(forKey: "escapeHTML")
    
    scriptSource =
         WOLinkGenerator.resourceLinkGenerator(keyedOn: "scriptSource",
                                               for:&bindings)
      ?? WOLinkGenerator.resourceLinkGenerator(keyedOn: "src", for:&bindings)
    
    self.template = template
    
    super.init(name: name, bindings: &bindings, template: template)
  }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }

    try response.appendBeginTag("script")
    try response.appendAttribute("language", "JavaScript")
    try response.appendAttribute("type",     "text/javascript")

    if let link = scriptSource?.fullHref(in: context) {
      try response.appendAttribute("href", link)
    }
    
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagEnd()
    
    let cursor = context.cursor
    
    /* comment if requested */
    
    let doHide   = hideInComment?.boolValue(in: cursor) ?? false
    let doEscape = escapeHTML?.boolValue(in: cursor) ?? true
    
    if doHide { try response.appendContentString("\n<!--\n") }

    /* tag content */
    
    /* scriptFile first, because its usually some kind of library(s) */
    if let v = scriptFile?.stringValue(in: cursor) {
      // TODO: support array
      if let s = try? String(contentsOf: URL(fileURLWithPath: v)) {
        if doEscape { try response.appendContentHTMLString(s) }
        else        { try response.appendContentString(s)     }
      }
      else {
        context.log.error("could not load script:", v)
      }
    }

    if let s = scriptString?.stringValue(in: cursor) {
      if doEscape { try response.appendContentHTMLString(s) }
      else        { try response.appendContentString(s)     }
    }

    
    /* close script tag */

    if let template = template {
      try template.append(to: response, in: context)
    }
    else {
      /* at least append a space, required by some browsers */
      try response.appendContentString(" ")
    }

    if doHide { try response.appendContentString("\n//-->\n") }
    try response.appendEndTag("script")
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if let link = scriptSource { ms += " src=\(link)" }
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "scriptFile",    scriptFile,
      "scriptString",  scriptString,
      "hideInComment", hideInComment,
      "escapeHTML",    escapeHTML
    )
  }
}

