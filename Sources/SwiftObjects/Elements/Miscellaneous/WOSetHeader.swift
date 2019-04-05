//
//  WOSetHeader.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

/*
 * This element can set/add a header field using -setHeader:forKey:. Usually its
 * used with a WOResponse (context.response is the default 'object'), but can be
 * used with arbitrary objects implementing the same API (eg context.request).
 *
 * Sample:
 * ```
 *   ChangeContentType: WOSetHeader {
 *     header = "content-type";
 *     value  = "text/plain";
 *   }
 * ```
 *
 * Renders:
 *   This element doesn't render any HTML. It adds a header to the contexts
 *   response.
 *
 * Bindings:
 * ```
 *   header|key|name [in] - string
 *   value           [in] - object
 *   addToExisting   [in] - boolean   (use appendHeader instead of setHeader)
 *   object          [in] - WOMessage (defaults to context.response)
 * ```
 */
open class WOSetHeader : WOHTMLDynamicElement {
  
  let object        : WOAssociation?
  let header        : WOAssociation?
  let value         : WOAssociation?
  let addToExisting : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    object        = bindings.removeValue(forKey: "object")
    value         = bindings.removeValue(forKey: "value")
    addToExisting = bindings.removeValue(forKey: "addToExisting")
    header        = bindings.removeValue(forKey: "header")
                 ?? bindings.removeValue(forKey: "key")
                 ?? bindings.removeValue(forKey: "name")
    
    super.init(name: name, bindings: &bindings, template: template)
  }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    let cursor = context.cursor
    guard let k = header?.stringValue(in: cursor) else { return }

    let doAdd = addToExisting?.boolValue(in: cursor) ?? false
    
    let v : String? = {
      guard let value = value else { return nil }
      let ov = value.value(in: cursor)
      // TODO: format Date/Calendar as HTTP
      return UObject.stringValue(ov)
    }()
    
    let lObject : WOMessage? = {
      guard let object = object else { return context.response }
      guard let ov = object.value(in: cursor) else { return nil }
      if let m = ov as? WOMessage { return m }
      if let s = ov as? String {
        if s == "response" { return context.response }
        if s == "request"  { return context.request  }
      }
      return nil
    }()
    
    guard let message = lObject else { return }
    
    if doAdd, let v = v { message.appendHeader(v, for: k) }
    else if   let v = v { message.setHeader   (v, for: k) }
    else                { message.removeHeaders(for: k)   }
  }
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "object",        object,
      "header",        header,
      "value",         value,
      "addToExisting", addToExisting
    )
  }
}
