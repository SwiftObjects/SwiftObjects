//
//  WOHTMLElementAttributes.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * An element used to generate the core set of attributes which can be assigned
 * to an HTML tag. Currently 'style' and 'class'.
 *
 * The element has support for dynamic creation of the contents of a style or
 * class attribute.
 * Contents of 'style' attributes are managed by bindings
 * which start using a '!'.
 * Contents of the CSS class are controlled by
 * bindings starting with a dot (.).
 *
 * Example:
 *
 *     <wo:div !display='none' style="color: red;">
 *
 * produces
 *
 *     <div style="color: red; display: none;">
 *
 * A very common usecase is dynamically adding classes, eg:
 *
 *     <wo:li .selected="$isSelectedPage">Customers</wo:li>
 *
 * Bindings (WOHTMLElementAttributes):
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg <input style="color:red;>)
 *   .key   [in]  - 'class' parameters (eg <input class="selected">)
 * ```
 */
open class WOHTMLElementAttributes : WODynamicElement {

  static let stylePrefix : Character = "!"
  static let classPrefix : Character = "."
  
  let style      : WOAssociation?
  let clazz      : WOAssociation?
  let dynStyles  : [ String : WOAssociation ]? /* all !style bindings */
  let dynClasses : [ String : WOAssociation ]? /* all .class bindings */

  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    style = bindings.removeValue(forKey: "style")
    clazz = bindings.removeValue(forKey: "class")
    
    var dynStyles  : [ String : WOAssociation ]? = nil
    var dynClasses : [ String : WOAssociation ]? = nil
    
    for ( key, assoc ) in bindings {
      guard let c0 = key.first else { continue }
      
      if c0 == WOHTMLElementAttributes.stylePrefix {
        if dynStyles == nil { dynStyles = [ String : WOAssociation ]() }
        let key1 = key[key.index(after: key.startIndex)..<key.endIndex]
        dynStyles![String(key1)] = assoc
        bindings.removeValue(forKey: key)
      }
      else if c0 == WOHTMLElementAttributes.classPrefix {
        if dynClasses == nil { dynClasses = [ String : WOAssociation ]() }
        let key1 = key[key.index(after: key.startIndex)..<key.endIndex]
        dynClasses![String(key1)] = assoc
        bindings.removeValue(forKey: key)
      }
    }
    
    self.dynStyles  = dynStyles
    self.dynClasses = dynClasses
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  /**
   * This element checks whether the associations Map contains any dynamic
   * class or style bindings. If yes, it creates a new WOHTMLElementAttributes
   * instances to generate those, if not, it returns null.
   *
   * @param _name  - the name of the new element (no internal use)
   * @param _assoc - the associations to be scanned for class/tyle
   * @return a dynamic element to generate the class/style attributes
   */
  public static func buildIfNecessary(name: String, bindings: inout Bindings)
                     -> WOHTMLElementAttributes?
  {
    guard !bindings.isEmpty else { return nil }
    
    for key in bindings.keys {
      guard let c0 = key.first else { continue }
      if c0 == WOHTMLElementAttributes.stylePrefix ||
         c0 == WOHTMLElementAttributes.classPrefix
      {
        return WOHTMLElementAttributes(name: name, bindings: &bindings,
                                       template: nil)
      }
      
      guard c0 == "s" || c0 == "c" else { continue }
      
      if key == "style" || key == "class" {
        return WOHTMLElementAttributes(name: name, bindings: &bindings,
                                       template: nil)
      }
    }
    
    return nil
  }
  
  
  // MARK: - Support
  
  /**
   * This evaluates each !style binding and returns the values in a Map.
   * For example:
   *
   *     !color = "red";
   *     !font  = "bold";
   *     !high  = null;
   *
   * Will be returned as `{ color = "red"; font = "bold"; }`.
   *
   * @param _cursor - the component for the evaluation of bindings
   * @return a Map containing the bindings, or null if none were found
   */
  func extractExtStyles(using cursor: Any?) -> [ String : Any ]? {
    guard let dynStyles = self.dynStyles else { return nil }
    var styles = [ String : Any ]()
    for ( cssStyleName, assoc ) in dynStyles {
      guard let v = assoc.value(in: cursor) else { continue }
      styles[cssStyleName] = v
    }
    return styles
  }
  
  /**
   * This method evaluates the .class bindings. The value of a .class binding
   * is a BOOLEAN, eg:
   *
   *     .selected = isPageSelected
   *
   * This will only ADD the 'selected' class if the isPageSelected binding
   * returns `true`.
   *
   * If the binding returns `nil`, the code will not do anything
   * with the class. If it returns `false` it will actually REMOVE
   * the class from the list.
   *
   * @param _cursor - the component for the evaluation of bindings
   * @return a List of CSS classnames
   */
  func extractExtClasses(using cursor: Any?) -> Set<String>? {
    guard let dynClasses = dynClasses else { return nil }
    
    var classes = Set<String>()
    
    // FIXME: I think the 'remove' is b0rked? It would need to add up?
    
    for ( cssClassName, assoc ) in dynClasses {
      /* Note how 'null' and 'false' are different. 'null' just doesn't add
       * the class, but 'false' actually removes the class.
       * TBD: would need to work with the base classes to be useful.
       */
      guard let v = assoc.value(in: cursor) else { continue }
      
      if UObject.boolValue(v) {
        classes.insert(cssClassName)
      }
      else {
        // TBD: not so useful unless it works on the full set of names?
        classes.remove(cssClassName)
      }
    }
    
    return classes.isEmpty ? nil : classes
  }
  
  func mapForStyles(_ styles: Any?) -> [ String : Any ] {
    guard let styles = styles else { return [:] }
    
    if let m = styles as? [ String : Any ] { return m }
    
    // TODO: support collection
    
    if let s = styles as? String {
      return parseCssStyles(s)
    }
    
    // TODO: fail
    return [:]
  }
  
  func listForClasses(_ classes: Any?) -> Set<String> {
    guard let classes = classes else     { return Set()  }
    if let s = classes as? Set<String>   { return s      }
    if let s = classes as? Array<String> { return Set(s) }
    
    if let s = classes as? String {
      /* simple parser, eg 'record even' */
      guard !s.isEmpty else { return Set() }
      return Set(s.split(separator: " ").map(String.init))
    }
    
    // TODO: fail
    return Set()
  }
  
  func parseCssStyles(_ s: String) -> [ String : Any ] {
    // TODO
    return [:]
  }
  
  /**
   * This method renders a few special object values, depending on the style
   * key.
   *
   * - 'padding', 'margin', 'border':
   *     the value can be a Map with 'top', 'right', 'bottom', 'left' keys
   * - Collection's are rendered as Strings with ", " between the values
   * - 'visibility', 'display', 'clear':
   *     the value can be a Boolean, it will render as 'visible'/'hidden',
   *     'block'/'none' and 'both'/'none'
   *
   * @param _key   - name of the style element, eg 'visibility'
   * @param _value - value to render
   * @param _sb    - the output buffer
   */
  func appendStyleValue(_ v: Any, for key: String, to sb: inout String) {
    if let s = v as? String {
      sb += s
      return
    }
    
    // TODO: port special cases: Map, Collection
    
    if let a = v as? [ String ] {
      var isFirst = true
      for s in a {
        if isFirst { isFirst = false }
        else { sb += ", " }
        sb += s
      }
      return
    }
    
    if let b = v as? Bool {
      switch key {
        case "visibility": sb += b ? "visible" : "hidden"
        case "display":    sb += b ? "block"   : "none"
        case "clear":      sb += b ? "both"    : "none"
        default: sb += b ? "true" : "false" // TBD
      }
      return
    }
    
    sb += "\(v)"
  }

  func stringForStyles(_ styles: Any?) -> String? {
    guard let styles = styles else { return nil }
    
    if let s = styles as? String { return s }
    
    if let m = styles as? [ String : Any ] {
      var sb = ""
      sb.reserveCapacity(m.count * 16)
      for ( key, value ) in m {
        if !sb.isEmpty { sb += " " }
        
        sb += key
        sb += ": "
        appendStyleValue(value, for: key, to: &sb)
        sb += ";"
      }
    }
    
    // TODO: fail
    return nil
  }
  
  func stringForClasses(_ classes: Any?) -> String? {
    guard let classes = classes else { return nil }
    if let s = classes as? String { return s.isEmpty ? nil : s }
    if let a = classes as? Set<String> {
      guard !a.isEmpty else { return nil }
      return a.joined(separator: " ")
    }
    if let a = classes as? Array<String> {
      guard !a.isEmpty else { return nil }
      return a.joined(separator: " ")
    }
    // TODO: fail
    return nil
  }

  
  // MARK: - Generate Response

  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    guard !context.isRenderingDisabled else { return }
    
    let cursor = context.cursor
    // FIXME: this is all very un-swifty
    
    /* calculate style */
    
    var baseStyle = self.style?.value(in: cursor)
    var extStyle  = self.extractExtStyles(using: cursor)
    if baseStyle == nil, let extStyle2 = extStyle {
      baseStyle = extStyle2
      extStyle  = nil
    }
    
    if let extStyle = extStyle {
      var baseMap = mapForStyles(baseStyle)
      let extMap  = mapForStyles(extStyle)
      baseMap.merge(extMap, uniquingKeysWith: { _, last in last })
      baseStyle = baseMap
    }
    
    /* calculate class */
    
    var baseClass = clazz?.value(in: cursor)
    var extClass  = extractExtClasses(using: cursor)
    if baseClass == nil && extClass != nil {
      baseClass = extClass
      extClass = nil
    }
    
    if let extClass = extClass {
      var baseSet = listForClasses(baseClass)
      let extSet  = listForClasses(extClass)
      baseSet.formUnion(extSet)
      baseClass = baseSet
    }
    
    /* generate */
    
    if let s = stringForClasses(baseClass), !s.isEmpty {
      try response.appendAttribute("class", s)
    }
    if let s = stringForStyles(baseStyle), !s.isEmpty {
      try response.appendAttribute("style", s)
    }
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "style", style,
      "class", clazz
    )
    
    for ( key, assoc ) in dynStyles ?? [:] {
      WODynamicElement.appendBindingToDescription(&ms, "!" + key, assoc)
    }
    for ( key, assoc ) in dynClasses ?? [:] {
      WODynamicElement.appendBindingToDescription(&ms, "." + key, assoc)
    }
  }
}
