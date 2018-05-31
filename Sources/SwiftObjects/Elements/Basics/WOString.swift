//
//  WOString.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * Just a plain, dynamic string. The 'value' can be an arbitrary object which is
 * then formatted using a Formatter.
 *
 * Sample:
 *
 *    ComponentName: WOString {
 *        value = name;
 *    }
 *
 * Renders:
 *   The element renders the given value, possibly after applying conversions.
 *
 * Bindings:
 * ```
 *   value          [in] - object
 *   valueWhenEmpty [in] - object
 *   escapeHTML     [in] - boolean (set to false to avoid HTML escaping)
 *   insertBR       [in] - boolean (replace newlines with &lt;br/&gt; tags)
 *   %value         [in] - string (pattern in %(keypath)s syntax)
 *   prefix         [in] - string (prefix for non-empty value)
 *   suffix         [in] - string (suffix for non-empty value)</pre>
 * Bindings (WOFormatter):<pre>
 *   calformat      [in] - a dateformat   (returns java.util.Calendar)
 *   dateformat     [in] - a dateformat   (returns java.util.Date)
 *   lenient        [in] - bool, only in combination with cal/dateformat!
 *   numberformat   [in] - a numberformat (NumberFormat.getInstance())
 *   currencyformat [in] - a numberformat (NumberFormat.getCurrencyInstance())
 *   percentformat  [in] - a numberformat (NumberFormat.getPercentInstance())
 *   intformat      [in] - a numberformat (NumberFormat.getIntegerInstance())
 *   formatterClass [in] - Class or class name of a formatter to use
 *   formatter      [in] - java.text.Format used to format the value or the
 *                         format for the formatterClass
 * ```
 *
 * If additional bindings are given, the text will get embedded into a tag
 * (defaults to 'span' if no other 'elementName' binding is given).
 *
 * Note: the tag is only rendered if there is content.
 */
open class WOString : WOHTMLDynamicElement {
  
  let value          : WOAssociation?
  let valuePattern   : WOAssociation?
  let valueWhenEmpty : WOAssociation?
  let escapeHTML     : WOAssociation?
  let insertBR       : WOAssociation?
  let prefix         : WOAssociation?
  let suffix         : WOAssociation?
  let formatter      : WOFormatter?
  let coreAttributes : WOElement?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    value          = bindings.removeValue(forKey: "value")
    valuePattern   = bindings.removeValue(forKey: "%value")
    escapeHTML     = bindings.removeValue(forKey: "escapeHTML")
    valueWhenEmpty = bindings.removeValue(forKey: "valueWhenEmpty")
    insertBR       = bindings.removeValue(forKey: "insertBR")
    prefix         = bindings.removeValue(forKey: "prefix")
    suffix         = bindings.removeValue(forKey: "suffix")
  
    formatter = WOFormatterFactory.formatter(for: &bindings)
    
    coreAttributes =
      WOHTMLElementAttributes.buildIfNecessary(name: name + "_core",
                                               bindings: &bindings)
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  public init(value: WOAssociation, escapeHTML: Bool = true) {
    self.value      = value
    self.escapeHTML = WOAssociationFactory.associationWithValue(escapeHTML)
    
    valuePattern   = nil
    valueWhenEmpty = nil
    insertBR       = nil
    prefix         = nil
    suffix         = nil
    formatter      = nil
    coreAttributes = nil

    var dummy = Bindings()
    super.init(name: "", bindings: &dummy, template: nil)
  }
  
  
  // MARK: - Generate Response
  
  func string(in context: WOContext) -> String? {
    let cursor = context.cursor
    var v      : Any? = nil
    
    if let value = value {
      v = value.value(in: cursor)
      
      if let valuePattern = valuePattern {
        if let pat = valuePattern.stringValue(in: cursor) {
          v = KeyValueStringFormatter.format(pat, object: v)
        }
        else {
          v = nil
        }
      }
    }
    else if let valuePattern = valuePattern {
      if let pat = valuePattern.stringValue(in: cursor) {
        v = KeyValueStringFormatter.format(pat, object: cursor)
      }
      else {
        v = nil
      }
    }
    else {
      v = nil // hm
    }
  
    /* valueWhenEmpty */
  
    if let s = v as? String, s.isEmpty {
      v = nil
    }
    if v == nil, let valueWhenEmpty = valueWhenEmpty {
      v = valueWhenEmpty.value(in: cursor)
    }
  
    /* format value */
    
    if let formatter = formatter {
      return formatter.string(for: v, in: context)
    }
    else if let value = v as? String {
      return value
    }
    else if let value = v {
      return String(describing: value)
    }
    else {
      return nil
    }
  }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    // method is pretty long, maybe we want to split it up
    guard !context.isRenderingDisabled else { return }
    
    let cursor   = context.cursor
    var doEscape = true
  
    /* determine string to render */
  
    var s = string(in: context)
    
    /* is escaping required? */
    
    if let escapeHTML = escapeHTML {
      doEscape = escapeHTML.boolValue(in: cursor)
    }
  
    /* insertBR processing */
    
    if let k = s, let insertBR = insertBR, insertBR.boolValue(in: cursor) {
      s = handleInsertBR(k, doEscape: doEscape)
      doEscape = false
    }
  
    /* append */
    
    guard let k = s, !k.isEmpty else { return }
    
    if !(extra?.isEmpty ?? true) || coreAttributes != nil {
      try appendWrappedString(to: response, in: context,
                              value: k, doEscape: doEscape)
    }
    else if doEscape {
      if let s = prefix?.stringValue(in: cursor), !s.isEmpty {
        try response.appendContentHTMLString(s)
      }
      
      try response.appendContentHTMLString(k)
      
      if let s = suffix?.stringValue(in: cursor), !s.isEmpty {
        try response.appendContentHTMLString(s)
      }
    }
    else {
      if let s = prefix?.stringValue(in: cursor), !s.isEmpty {
        try response.appendContentString(s)
      }
      
      try response.appendContentString(k)

      if let s = suffix?.stringValue(in: cursor), !s.isEmpty {
        try response.appendContentString(s)
      }
    }
  }
  
  /**
   * Rewrites \n characters to <br /> tags. Note: the result must not be
   * escaped in subsequent processing.
   *
   * @param _s        - String to rewrite
   * @param _doEscape - whether the parts need to be escaped
   * @return the rewritten string
   */
  func handleInsertBR(_ s: String, doEscape: Bool, tag: String = "<br />")
       -> String
  {
    /* Note: we can't use replace() because we need to escape the individual
     *       parts.
     */
    #if swift(>=4.1)
      if doEscape {
        return s.lazy.split(separator: "\n", omittingEmptySubsequences: false)
                     .map { $0.htmlEscaped }
                     .joined(separator: tag)
      }
      else {
        return s.lazy.split(separator: "\n", omittingEmptySubsequences: false)
                     .joined(separator: tag)
      }
    #else
      if doEscape {
        return s.split(separator: "\n", omittingEmptySubsequences:false)
                .map { $0.htmlEscaped }
                .joined(separator: tag)
      }
      else {
        return s.split(separator: "\n", omittingEmptySubsequences: false)
                .joined(separator: tag)
      }
    #endif
  }
  
  /**
   * Embeds the String in an HTML tag, &lt;span&gt; per default.
   *
   * @param _r       - the WOResponse to add to
   * @param _ctx     - the WOContext in which the operation runs
   * @param s        - the already formatted string to render
   * @param doEscape - whether to use appendContentHTMLString() or not
   */
  func appendWrappedString(to response: WOResponse, in context: WOContext,
                           value s: String, doEscape: Bool) throws
  {
    /* this allows you to attach attributes to a text :-) */
    let cursor      = context.cursor
    let elementName = extra?["elementName"]?.stringValue(in: cursor) ?? "span"
    
    /* start tag */
  
    try response.appendBeginTag(elementName);
  
    /* render attributes */
  
    if let coreAttributes = coreAttributes {
      try coreAttributes.append(to: response, in: context)
    }
  
    if let extra = extra {
      for ( key, assoc ) in extra {
        guard key != "elementName" else { continue }
        try response.appendAttribute(key, assoc.stringValue(in: cursor))
      }
    }
    
    /* finish start tag */
    
    try response.appendBeginTagEnd()
  
    /* render content */

    let p = prefix?.stringValue(in: cursor)
    let t = suffix?.stringValue(in: cursor)
    if (doEscape) {
      if let s = p { try response.appendContentHTMLString(s) }
      try response.appendContentHTMLString(s);
      if let s = t { try response.appendContentHTMLString(s) }
    }
    else {
      if let s = p { try response.appendContentString(s) }
      try response.appendContentString(s);
      if let s = t { try response.appendContentString(s) }
    }
  
    /* end tag */
  
    try response.appendEndTag(elementName)
  }
  
  
  // MARK: - Description

  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
  
    WOString.appendBindingsToDescription(&ms,
      "value",          value,
      "valuePattern",   valuePattern,
      "valueWhenEmpty", valueWhenEmpty,
      "escapeHTML",     escapeHTML,
      "insertBR",       insertBR
    )
  
    if let v = formatter { ms += " formatter=\(v)" }
  }
}
