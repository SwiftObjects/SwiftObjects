//
//  WOForm.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * Sample:
 *
 *     Form: WOForm {
 *         directActionName = "postComment";
 *         actionClass      = "CommentPage";
 *     }
 *
 * Renders:
 *
 *     <form href="/servlet/app/wa/CommentPage/postComment?comment=blub">
 *       [sub-template]
 *     </form>
 *
 * Bindings:
 * ```
 *   id                 [in]  - string (elementID and HTML DOM id)
 *   target             [in]  - string
 *   method             [in]  - string (POST/GET)
 *   errorReport        [i/o] - WOErrorReport (autocreated when null) / bool
 *   forceTakeValues    [in]  - boolean (whether the form *must* run takeValues)
 * ```
 * Bindings (WOLinkGenerator):
 * ```
 *   href               [in] - string
 *   action             [in] - action
 *   pageName           [in] - string
 *   directActionName   [in] - string
 *   actionClass        [in] - string
 *   fragmentIdentifier [in] - string
 *   queryDictionary    [in] - Map<String,Object>
 *   ?wosid             [in] - boolean (constant!)
 *   - all bindings starting with a ? are stored as query parameters.
 * ```
 *
 * Bindings (WOHTMLElementAttributes):<pre>
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg <input style="color:red;">)
 *   .key   [in]  - 'class' parameters (eg <input class="selected">)
 * ```
 */
open class WOForm : WOHTMLDynamicElement {
  
  let id              : WOAssociation?
  let target          : WOAssociation?
  let method          : WOAssociation?
  let forceTakeValues : WOAssociation?
  let errorReport     : WOAssociation?
  
  let link            : WOLinkGenerator?
  let coreAttributes  : WOElement?
  let template        : WOElement?

  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    id              = bindings.removeValue(forKey: "id");
    target          = bindings.removeValue(forKey: "target");
    method          = bindings.removeValue(forKey: "method");
    errorReport     = bindings.removeValue(forKey: "errorReport");
    forceTakeValues = bindings.removeValue(forKey: "forceTakeValues");
    
    link          = WOLinkGenerator.linkGenerator(for: &bindings)
    self.template = template

    bindings.removeValue(forKey: "multipleSubmit") /* not required in Go? */

    coreAttributes = WOHTMLElementAttributes
      .buildIfNecessary(name: name + "_core", bindings: &bindings)
    
    super.init(name: name, bindings: &bindings, template: template)
  }

  
  // MARK: - Responder
  
  /**
   * Returns a new or existing WOErrorReport object for the given WOContext.
   * This checks the 'errorReport' associations, which can have those values:
   *
   * - null! - if the binding is set, but returns null, a NEW error report
   *       will be created and pushed to the binding
   * - WOErrorReport - a specific object is given
   * - Boolean true/false - if true, a new report will be created
   * - String evaluated as a Boolean (eg "true"/"false"), same like above
   *
   * Note: This does NOT touch the WOContext's active errorReport. Its only
   *       used to setup new reports using the 'errorReport' binding.
   *
   * @param the active WOContext
   */
  open func prepareErrorReportObject(in context: WOContext) -> WOErrorReport? {
    guard let errorReport = errorReport else { return nil }
    
    let cursor = context.cursor
    let vr = errorReport.value(in: cursor)
    if let er = vr as? WOErrorReport { return er } // assigned already
    
    if vr == nil {
    }
    else if let b = vr as? Bool {
      if !b { return nil } /* requested NO error report */
    }
    else if let s = vr as? String {
      if !UObject.boolValue(s) { return nil } /* requested NO error report */
    }
    else {
      context.log.error("unexpected value in 'errorReport' binding:", vr)
      return nil
    }
    
    /* build new error report and push it */
    
    let er = WOErrorReport()
    if errorReport.isValueSettableInComponent(cursor) {
      try? errorReport.setValue(er, in: cursor) // TBD
    }
    return er
  }
 
  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    if context.isInForm { context.log.warn("detected nested form:", self) }
    
    let cursor = context.cursor
    var oldId  : String? = nil
    var lid    = context.elementID
    let v      = id?.value(in: cursor)

    if v is Bool { /* in this mode we just expose the ID in HTML */
    }
    else if let v = v {
      oldId = lid
      lid   = (v as? String) ?? String(describing: v)
    }
    
    /* push an WOErrorReport object to the WOContext */
    let er = prepareErrorReportObject(in: context)
    if let er = er { context.pushErrorReport(er) }

    context.isInForm = true
    
    defer {
      if !context.isInForm {
        context.log.error("inconsistent form setup detected!")
      }
      context.isInForm = false
      
      if let oldId = oldId {
        /* restore old ID */
        context.elementID = oldId
      }
      
      if er != nil { _ = context.popErrorReport() }
    }
    
    context.elementID = lid
    
    /* apply values to ?style parameters */
    try link?.takeValues(from: request, in: context)
    
    guard let template = template else { return }
    
    var doTakeValues = false
    
    if forceTakeValues?.boolValue(in: cursor) ?? false {
      doTakeValues = true
    }
    else if let link = link {
      doTakeValues = link.shouldFormTakeValues(from: request, in: context)
    }
    else {
      doTakeValues = context.request.method == "POST"
    }
    
    if let xoldId = oldId {
      /* restore old ID */
      context.elementID = xoldId
      oldId = nil
    }
    
    if doTakeValues {
      try template.takeValues(from: request, in: context)
    }
  }
  
  override
  open func invokeAction(for request: WORequest, in context: WOContext) throws
            -> Any?
  {
    if context.isInForm { context.log.warn("detected nested form:", self) }
    
    let cursor = context.cursor
    context.isInForm = true
    defer {
      context.isInForm = false
    }

    /* Active form elements like WOSubmitButton register themselves as active
     * during the take values phase if their form-value matches the senderID.
     * If no element was activated, the WOForm action will get executed if the
     * form ID matches the sender-ID.
     */
    if context.activeFormElement != nil {
      /* active element was selected before */
      // TODO: do we need to patch the senderID? Hm, no, the senderID is
      //       patched by the setActiveFormElement() thingy
      // But: we need to patch the elementID, so that it matches the sender..
      //oldId = _ctx.elementID();
      //_ctx._setElementID(_ctx.senderID());
      // => no we don't need this either
    }
    else {
      /* No form element got activated, so we run the WOForm action if the
       * sender-id matches.
       */
      var oldId : String? = nil
      var lid   = context.elementID
      let v     = id?.value(in: cursor)
      
      if v is Bool {
        /* in this mode we just expose the ID in HTML */
      }
      else if let v = v { /* explicit ID was assigned */
        oldId = lid
        lid   = (v as? String) ?? String(describing: v)
      }

      if lid == context.senderID {
        /* we are responsible, great */
        if let link = link {
          if oldId != nil { /* push own id */
            context.elementID = lid
          }
          
          let result = try link.invokeAction(for: request, in: context)
                    ?? context.page   // make it work w/ CompoundElement
                    ?? context.cursor // no page but an active component?
          
          if let oldId = oldId {
            /* restore old ID */
            context.elementID = oldId
          }
          
          /* we are done, return result */
          return result
        }

        context.log.warn("no action configured for link invocation:", self)
      }
    }
    
    /* Note: we do not directly call the element so that repetitions etc
     * are properly processed to setup the invocation environment.
     */
    if let template = template {
      return try template.invokeAction(for: request, in: context)
    }
    if let element = context.activeFormElement { // should never happen
      return try element.invokeAction(for: request, in: context)
    }
    
    return nil
  }
  
  
  // MARK: - Generate Response
  
  /**
   * Adds the opening `<form>` tag to the response, including parameters
   * like:
   * - id
   * - action
   * - method
   * - target
   * and those supported by {@link WOHTMLElementAttributes}.
   */
  func appendCoreAttributes(id: String?,
                            to response: WOResponse, in context: WOContext)
         throws
  {
    let cursor = context.cursor
    
    try response.appendBeginTag("form")
    if let v = id { try response.appendAttribute("id", v) }
    
    if let link = link {
      if let url = link.fullHref(in: context) {
        /* Note: this encodes the ampersands in query strings as &amp;! */
        try response.appendAttribute("action", url)
      }
    }
    else {
      /* a form MUST have some target, no? */
      try response.appendAttribute("action", context.componentActionURL())
    }
    
    let m = method?.stringValue(in: cursor) ?? "POST"
    try response.appendAttribute("method", m)
    
    if let target = target {
      try response.appendAttribute("target", target.stringValue(in: cursor))
    }
    
    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagEnd();
  }
  
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    if context.isInForm { context.log.warn("detected nested form:", self) }
    
    /* Note: prepare does NOT touch the WOContext, eg extract a pushed report */
    let er = prepareErrorReportObject(in: context)
    if let er = er { context.pushErrorReport(er) }
    
    context.isInForm = true
    defer {
      if !context.isInForm {
        context.log.error("inconsistent form setup detected!");
      }
      context.isInForm = false

      if er != nil { _ = context.popErrorReport() }
    }

    guard !context.isRenderingDisabled else {
      try template?.append(to: response, in: context)
      return
    }
    
    let cursor = context.cursor
    var lid    : String? = nil
    var oldid  : String? = nil
    
    if let id = id {
      lid = id.stringValue(in: cursor)
    }
    if let lid = lid {
      oldid = context.elementID
      context.elementID = lid
    }
    defer {
      if let oldid = oldid {
        context.elementID = oldid
      }
    }
    
    /* start form tag */
    try appendCoreAttributes(id: lid, to: response, in: context)
    
    /* render form content */
    try template?.append(to: response, in: context)
    
    /* render form close tag */
    try response.appendEndTag("form")
  }
  
  
  // MARK: - Generic Template Walking
  
  override
  open func walkTemplate(using walker: WOElementWalker, in context: WOContext)
              throws
  {
    if context.isInForm { context.log.warn("detected nested form:", self) }
    guard let template = template else { return }

    context.isInForm = true
    defer {
      if !context.isInForm {
        context.log.error("inconsistent form setup detected!");
      }
      context.isInForm = false
    }
    
    _ = try walker(self, template, context)
  }

  
  // MARK: - Description

  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WOString.appendBindingsToDescription(&ms,
      "id",              id,
      "method",          method,
      "target",          target,
      "errorReport",     errorReport,
      "forceTakeValues", forceTakeValues
    )
  }

}
