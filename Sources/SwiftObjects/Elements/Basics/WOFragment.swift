//
//  WOFragment.swift
//  SwiftObjects
//
//  Created by Helge Hess on 28.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

/**
 * This element is used to mark rendering fragments. If Go receives a URL
 * which contains the 'wofid' request parameter, it will disable rendering in
 * the WOContext. This element can be used to reenable rendering for a certain
 * template subsection.
 *
 * Note that request handling is NOT affected by fragments! This is necessary
 * to ensure a proper component state setup. If you wish, you can further
 * reduce processing overhead using WOConditionals in appropriate places (if
 * you know that those sections do not matter for processing)
 *
 * Fragments can be nested. WOFragment sections _never_ disable rendering or
 * change template control flow, they only enable rendering when fragment ids
 * match. This way it is ensured that "sub fragments" will get properly
 * accessed.
 * This can be overridden by setting the "onlyOnMatch" binding. If this is set
 * the content will only get accessed in case the fragment matches OR no
 * fragment id is set (in the request).
 *
 * Sample:
 *
 *     <wo:fragment name="tableview" />
 *
 * Renders:
 *
 *     This element can render a container tag if the elementName is specified.
 *
 * Bindings:
 * ```
 *   name        [in] - string       name of fragment
 *   onlyOnMatch [in] - boolean      enable/disable processing for other frags
 *   elementName [in] - string       optional name of container element
 *   TBD: wrong?[all other bindings are extra-attrs for elementName]
 * ```
 */
open class WOFragment : WODynamicElement {
  
  let name        : WOAssociation?
  let id          : WOAssociation?
  let onlyOnMatch : WOAssociation?
  let elementName : WOAssociation?
  let template    : WOElement?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    self.name   = bindings.removeValue(forKey: "name")
    id          = bindings.removeValue(forKey: "id")
    onlyOnMatch = bindings.removeValue(forKey: "onlyOnMatch")
    elementName = bindings.removeValue(forKey: "elementName")
    
    self.template = template
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  
  // MARK: - Active
  
  func fragmentName(in context: WOContext) -> String? {
    guard let a = name else { return context.elementID }
    return a.stringValue(in: context.cursor)
  }
  
  func isFragmentActive(in context: WOContext) -> Bool {
    guard let rqFragID = context.fragmentID else {
      return true // active, no fragment is set
    }
    guard let fragName = fragmentName(in: context) else {
      return true // we have no fragid in the current state
    }
    
    guard fragName == rqFragID else { return false } // mismatch
    return true
  }
  
  func isFragmentActiveAndMatches(in context: WOContext) -> Bool {
    guard let a = onlyOnMatch else { return true } // not only on match
    if a.boolValue(in: context.cursor) {
      return isFragmentActive(in: context)
    }
    return true
  }

  
  // MARK: - Responder
  
  override open func takeValues(from request: WORequest,
                                in context: WOContext) throws
  {
    guard let template = template else { return }
    
    if isFragmentActiveAndMatches(in: context) {
      try template.takeValues(from: request, in: context)
    }
  }
  
  override open func invokeAction(for request : WORequest,
                                  in  context : WOContext) throws -> Any?
  {
    guard let template = template else { return nil }

    if context.fragmentID == nil || isFragmentActiveAndMatches(in: context) {
      return try template.invokeAction(for: request, in: context)
    }
    
    /* onlyOnMatch is on and fragment is not active, do not call template */
    return nil
  }
  
  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    let cursor       = context.cursor
    let wasDisabled  = context.isRenderingDisabled
    let isFragActive = isFragmentActive(in: context)
    let doRender     = isFragActive
                    || (onlyOnMatch?.boolValue(in: cursor) ?? true)
    
    /* enable rendering if we are active */
    if isFragActive && wasDisabled {
      context.enableRendering()
    }
    defer {
      if isFragActive && wasDisabled {
        context.disableRendering()
      }
    }

    /* start container element if we have no frag */
    let en : String?
    if !wasDisabled, let a = elementName {
      en = a.stringValue(in: cursor)
    }
    else {
      en = nil
    }
    
    if let en = en {
      let leid : String? = {
        if let id = id   { return id.stringValue(in: cursor) }
        if let n  = name { return n .stringValue(in: cursor) }
        return context.elementID
      }()
      
      try response.appendBeginTag(en)
      if let lid = leid {
        try response.appendAttribute("id", lid)
      }
      try appendExtraAttributes(to: response, in: context)
      try response.appendBeginTagEnd()
    }
    
    if doRender, let template = template {
      try template.append(to: response, in: context)
    }
    
    if let en = en {
      try response.appendEndTag(en)
    }
  }

  override open func walkTemplate(using walker : WOElementWalker,
                                  in   context : WOContext) throws
  {
    try template?.walkTemplate(using: walker, in: context)
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)

    WODynamicElement.appendBindingsToDescription(&ms,
      "name",        name,
      "id",          id,
      "onlyOnMatch", onlyOnMatch,
      "elementName", elementName
    )
  }
}

