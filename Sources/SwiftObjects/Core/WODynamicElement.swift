//
//  WODynamicElement.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * This is the abstract superclass for _stateless_ and reentrant parts of a
 * template. Subclasses MUST NOT store any processing state in instance
 * variables because they can be accessed concurrently by multiple threads and
 * even by one thread.
 *
 * ### Extra Bindings
 *
 * This element also tracks 'extra bindings'. Those are bindings which where
 * not explicitly grabbed (removed from the '_assocs' ctor Map) by subclasses.
 * What is done with those extra bindings depends on the subclass, usually
 * they are added to the HTML tag which is managed by the dynamic element.
 * For example extra-attrs in a WOHyperlink are (usually) added to the <a>
 * tag.
 *
 * Further 'extra bindings' can be `%(key)s` style patterns IF
 * the value starts with a % sign. Example:
 *
 *     <wo:span varpat:id="employee-%(person.id)s">...<wo:span>
 *     <wo:a varpat:onclick="alert('clicked %(person.name)s');" />
 *
 * Those patterns are resolved using the KeyValueStringFormatter.format()
 * function.
 */
open class WODynamicElement : WOElement, SmartDescription {
  
  var otherTagString : WOAssociation?
  var extra          : [ String : WOAssociation ]?
  
  public required init(name: String, bindings: inout Bindings,
                       template: WOElement?)
  {
  }
  
  /**
   * Usually called by the WOWrapperTemplateBuilder to apply bindings which
   * did not get grabbed in the constructor of the element.
   *
   * @param _attrs - the bindings map (often empty)
   */
  public func setExtraAttributes(_ associations: inout Bindings) {
    otherTagString = associations.removeValue(forKey: "otherTagString")
    extra          = associations
    associations.removeAll()
  }
  
  // TODO: implement / port me
 
  /**
   * The method walks over all 'extraKeys'. If the key starts with a '%'
   * sign, the value of the key is treated as pattern for the
   * KeyValueStringFormatter.format() function.
   *
   * @param _r - the WOResponse
   * @param _c - the WOContext
   * @param _patObject - the pattern object, usually the active WOComponent
   */
  func appendExtraAttributes(to response   : WOResponse,
                             in context    : WOContext,
                             patternObject : Any? = nil) throws
  {
    guard let extra = extra else { return }
    
    /* we could probably improve the speed of the pattern processor ... */
    let cursor    = context.cursor
    let patObject = patternObject ?? cursor
    
    for ( key, assoc ) in extra {
      guard let v = assoc.stringValue(in: cursor) else { continue }
      
      // TBD: I don't think this makes a lot of sense? Either the whole value is
      //      always a pattern or not? (better not?!)
      if key.hasPrefix("%") {
        let nk = String(key[key.index(after: key.startIndex)..<key.endIndex])
        let fv = KeyValueStringFormatter.format(v, object: patObject)
        try response.appendAttribute(nk, fv)
      }
      else {
        try response.appendAttribute(key, v)
      }
    }
  }
  
  
  // MARK: - Default Implementations
  
  open func takeValues(from request: WORequest, in context: WOContext) throws {}
  
  open func invokeAction(for request: WORequest, in context: WOContext) throws
            -> Any?
  {
    return nil
  }
  
  open func append(to response: WOResponse, in context: WOContext) throws {}
  
  open func walkTemplate(using walker: WOElementWalker, in context: WOContext)
              throws
  {
  }

  
  // MARK: - Description

  open func appendToDescription(_ ms: inout String) {
    // nothing
  }

  /**
   * Utility function to add WOAssociation ivar info to a description string.
   * Example:
   *
   *     appendAssocToDescription(_d, "id", this.idBinding)
   *
   * @param _d    - the String to add the description to
   * @param _name - name of the binding
   * @param _a    - WOAssociation object used as the binding value
   */
  public static func appendBindingToDescription(_ ms    : inout String,
                                                _ name  : String,
                                                _ assoc : WOAssociation?)
  {
    guard let assoc = assoc else { return }
    
    ms += " "
    ms += name
    ms += "="
    
    // TODO: make output even smarter ;-)
    if !assoc.isValueConstant {
      ms += "\(assoc)"
      return
    }
  
    /* constant assocs */
    
    guard let v = assoc.value(in: nil) else {
      ms += " null"
      return
    }
    
    if let s = v as? String {
      ms += "\""
      if s.count > 79 {
        ms += s[s.startIndex..<s.index(s.startIndex, offsetBy: 76)]
        ms += "..."
      }
      else {
        ms += s
      }
      ms += "\""
    }
    else {
      ms += "\"\(v)\""
    }
  }
  
  public static func appendBindingsToDescription(_ ms       : inout String,
                                                 _ bindings : Any?...)
  {
    guard !bindings.isEmpty else { return }
    
    for i in stride(from: 0, to: bindings.endIndex, by: 2) {
      guard i + 1 < bindings.endIndex         else { continue }
      guard let name  = bindings[i] as? String else { continue } // TODO: fail
      guard let assoc = bindings[i + 1] as? WOAssociation else { continue }
      appendBindingToDescription(&ms, name, assoc)
    }
  }
}
