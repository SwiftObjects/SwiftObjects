//
//  WOHyperlink.swift
//  SwiftObjects
//
//  Created by Helge Hess on 20.05.18.
//

/**
 * Sample:
 *
 *     Link: WOHyperlink {
 *         directActionName = "postComment";
 *         actionClass      = "CommentPage";
 *         ?comment         = "blub";
 *     }
 *
 * Renders:
 *
 *     <a href="/servlet/app/wa/CommentPage/postComment?comment=blub">
 *       [sub-template]
 *     </a>
 *
 * Bindings (WOLinkGenerator):
 * ```
 *   href                 [in] - string
 *   action               [in] - action
 *   pageName             [in] - string
 *   directActionName     [in] - string
 *   actionClass          [in] - string
 *   fragmentIdentifier   [in] - string
 *   queryDictionary      [in] - Dictionary<String,String>
 *   - all bindings starting with a ? are stored as query parameters.
 *   - support for !style and .class attributes (WOHTMLElementAttributes)
 * ```
 * Regular bindings:
 * ```
 *   id                   [in] - string
 *   string / value       [in] - string
 *   target               [in] - string
 *   disabled             [in] - boolean (only render content, not the anker)
 *   disableOnMissingLink [in] - boolean
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
open class WOHyperlink : WOHTMLDynamicElement {
  
  let id                   : WOAssociation? // the element and DOM ID
  let target               : WOAssociation?
  let disabled             : WOAssociation?
  let disableOnMissingLink : WOAssociation?
  let template             : WOElement?
  let link                 : WOLinkGenerator?
  let string               : WOElement?
  let coreAttributes       : WOElement?

  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    id                   = bindings.removeValue(forKey: "id")
    target               = bindings.removeValue(forKey: "target")
    disabled             = bindings.removeValue(forKey: "disabled")
    disableOnMissingLink = bindings.removeValue(forKey: "disableOnMissingLink")
    
    link = WOLinkGenerator.linkGenerator(for: &bindings)
    
    /* content */
    
    self.template = template
    
    if let a = bindings.removeValue(forKey: "string")
            ?? bindings.removeValue(forKey: "value")
    {
      var ecAssocs = Bindings()
      ecAssocs["value"] = a
      [ "dateformat", "numberformat", "formatter", "formatterClass" ].forEach {
        guard let a = bindings.removeValue(forKey: $0) else { return }
        ecAssocs[$0] = a
      }
      self.string = WOString(name: name + "_string", bindings: &ecAssocs,
                             template: nil)
      assert(ecAssocs.isEmpty)
    }
    else {
      self.string = nil
    }
    
    coreAttributes = WOHTMLElementAttributes
                  .buildIfNecessary(name: name + "_core", bindings: &bindings)
    
    super.init(name: name, bindings: &bindings, template: template)
  }

  override open func takeValues(from request: WORequest,
                                in context: WOContext) throws
  {
    /* links can take form values!! (for query-parameters) */
    
    if let a = disabled, a.boolValue(in: context.cursor) { return }

    if let link = link {
      try link.takeValues(from: request, in: context)
    }
    
    try template?.takeValues(from: request, in: context)
  }
  
  override open func invokeAction(for request : WORequest,
                                  in  context : WOContext) throws -> Any?
  {
    let cursor = context.cursor
    if let a = disabled, a.boolValue(in: cursor) { return nil }
    
    var oldId : String? = nil
    var lid   = context.elementID
    let v     = id?.value(in: cursor)
    if v is Bool { /* in this mode we just expose the ID in HTML */
    }
    else if let v = v {
      oldId = lid
      lid = (v as? String) ?? String(describing: v)
    }
    
    var result : Any?
    if lid == context.senderID {
      guard let link = link else {
        context.log.warn("no action configure for link invocation:", self)
        return nil
      }
      
      if oldId == nil { // push own ID
        context.elementID = lid
      }
      
      result = try link.invokeAction(for: request, in: context)
            ?? context.page
            ?? cursor

      if let oldId = oldId { // restore old ID
        context.elementID = oldId
      }
    }
    else {
      result = try template?.invokeAction(for: request, in: context)
    }

    return result
  }
  
  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    guard !context.isRenderingDisabled else {
      try template?.append(to: response, in: context)
      return
    }
    
    let cursor = context.cursor
    
    var doNotDisplay = disabled?.boolValue(in: cursor) ?? false
    
    var oldId : String? = nil
    var lid   : String? = nil
    let url   : String?
    
    if !doNotDisplay {
      let v = id?.value(in: cursor)
      if v is Bool { /* in this mode we just expose the ID in HTML */
        lid = context.elementID
      }
      else if let v = v {
        oldId = context.elementID
        lid = (v as? String) ?? String(describing: v)
        context.elementID = lid!
      }
      
      url = link?.fullHref(in: context)
      if url == nil, let a = disableOnMissingLink {
        doNotDisplay = a.boolValue(in: cursor)
      }
    }
    else {
      url = nil
    }
    
    if !doNotDisplay {
      try response.appendBeginTag("a")
      if let url = url { try response.appendAttribute("href", url) }
      if let lid = lid { try response.appendAttribute("id",   lid) }
      if let s = target?.stringValue(in: cursor) {
        try response.appendAttribute("target", s)
      }
      try coreAttributes?.append(to: response, in: context)
      try appendExtraAttributes(to: response, in: context)
      try response.appendBeginTagEnd()
    }
    
    if let oldId = oldId {
      context.elementID = oldId
    }

    try template?.append(to: response, in: context)
    try string?  .append(to: response, in: context)
    
    if !doNotDisplay {
      try response.appendEndTag("a")
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
      "id",                   id,
      "target",               target,
      "disabled",             disabled,
      "disableOnMissingLink", disableOnMissingLink
    )
  }
}
