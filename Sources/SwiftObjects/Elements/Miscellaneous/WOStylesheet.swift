//
//  WOStylesheet.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * Generate a style tag containing CSS code or a link tag.
 *
 * Sample:
 *
 *     Style: WOStylesheet {
 *         filename = "site.css";
 *     }
 *
 * Renders:<pre>
 * ```
 *   <link rel="stylesheet" type="text/css"
 *         href="/MyApp/wr/site.css" />
 * ```
 *
 * Bindings:
 * ```
 *   cssResource      [in] - string          (name of a WOResource to be emb.)
 *   cssFile          [in] - string/File/URL (contents will be embedded)
 *   cssString        [in] - string          (will be embedded)
 *   hideInComment    [in] - bool
 *   escapeHTML       [in] - boolean (set to false to avoid HTML escaping)
 * ```
 *
 * Bindings (WOLinkGenerator for image resource):
 * ```
 *   href             [in] - string
 *   filename         [in] - string
 *   framework        [in] - string
 *   actionClass      [in] - string
 *   directActionName [in] - string
 *   queryDictionary  [in] - Map<String,String>
 *   ?wosid           [in] - boolean (constant!)
 *   - all bindings starting with a ? are stored as query parameters.
 * ```
 */
open class WOStylesheet : WOHTMLDynamicElement {
  
  let href          : WOLinkGenerator?
  let cssFile       : WOAssociation?
  let cssResource   : WOAssociation?
  let cssString     : WOAssociation?
  let hideInComment : WOAssociation?
  let escapeHTML    : WOAssociation?
  let template      : WOElement?

  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    cssFile       = bindings.removeValue(forKey: "cssFile")
    cssResource   = bindings.removeValue(forKey: "cssResource")
    cssString     = bindings.removeValue(forKey: "cssString")
    hideInComment = bindings.removeValue(forKey: "hideInComment")
    escapeHTML    = bindings.removeValue(forKey: "escapeHTML")

    href = WOLinkGenerator.resourceLinkGenerator(keyedOn: "href", for:&bindings)
    self.template = template
    
    super.init(name: name, bindings: &bindings, template: template)
  }

  func appendStyleTag(to response: WOResponse, in context: WOContext) throws {
    let cursor = context.cursor
    
    /* open style-tag */
    
    try response.appendBeginTag("style")
    try response.appendAttribute("type", "text/css")
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagEnd()
    
    /* comment if requested */
    
    let doHide   = hideInComment?.boolValue(in: cursor) ?? false
    let doEscape = escapeHTML?.boolValue(in: cursor) ?? true
    
    if doHide { try response.appendContentString("\n<!--\n") }
    
    /* tag content */
    
    /* cssFile first, because its usually some kind of library(s) */
    if let v = cssFile?.stringValue(in: cursor) {
      // TODO: support array
      if let s = try? String(contentsOf: URL(fileURLWithPath: v)) {
        if doEscape { try response.appendContentHTMLString(s) }
        else        { try response.appendContentString(s)     }
      }
      else {
        context.log.error("could not load stylesheet:", v)
      }
    }
    
    if let rn = cssResource?.stringValue(in: cursor) {
      let rm = context.component?.resourceManager
            ?? context.application.resourceManager
      
      if let data = rm?.dataForResourceNamed(rn, languages: []) {
        if doEscape {
          if let s = String(data: data, encoding: .utf8) {
            try response.appendContentHTMLString(s)
          }
          else {
            context.log.error("could not convert CSS to string:", rn)
          }
        }
        else {
          try response.appendContentData(data)
        }
      }
      else {
        context.log.error("did not find CSS:", rn)
      }
    }
    
    if let s = cssString?.stringValue(in: cursor) {
      if doEscape { try response.appendContentHTMLString(s) }
      else        { try response.appendContentString(s)     }
    }
    
    /* close style tag */
    
    if let template = template {
      try template.append(to: response, in: context)
    }
    else {
      /* at least append a space, required by some browsers */
      try response.appendContentString(" ")
    }
    
    if doHide { try response.appendContentString("\n//-->\n") }
    try response.appendEndTag("style")
  }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    if let link = href?.fullHref(in: context) {
      try response.appendBeginTag("link")
      try response.appendAttribute("rel",  "stylesheet")
      try response.appendAttribute("type", "text/css")
      try response.appendAttribute("href", link)
      try appendExtraAttributes(to: response, in: context)
      try response.appendBeginTagClose(context.closeAllElements)
    }

    /* should we generate a style tag */
    
    if cssFile != nil || cssString != nil || cssResource != nil ||
       template != nil
    {
      try appendStyleTag(to: response, in: context)
    }
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if let link = href { ms += " src=\(link)" }
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "cssFile",       cssFile,
      "cssResource",   cssResource,
      "cssString",     cssString,
      "hideInComment", hideInComment,
      "escapeHTML",    escapeHTML
    )
  }
}

