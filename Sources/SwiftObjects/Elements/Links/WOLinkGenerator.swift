//
//  WOLinkGenerator.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * This is a helper class to generate URLs for hyperlinks, forms and such. It
 * encapsulates the various options available.
 *
 * The main entry point is the linkGeneratorForAssociations() factory method.
 */
open class WOLinkGenerator : WOElement, SmartDescription {
  
  public typealias Bindings = [ String : WOAssociation ]
  
  public let fragmentIdentifier : WOAssociation?
  
  let queryDictionary : WOAssociation?
  let sidInURL        : WOAssociation?
  
  /// associations beginning with a `?`
  let queryParameters : Bindings?
  
  
  // MARK: - Factory

  public static func linkGenerator(for associations: inout Bindings)
                       -> WOLinkGenerator?
  {
    if associations["href"] != nil {
      return WOHrefLinkGenerator(staticKey: "href", associations: &associations)
    }
    
    if associations["directActionName"] != nil ||
       associations["actionClass"] != nil
    {
      return WODirectActionLinkGenerator(associations: &associations)
    }
    
    if associations["pageName"] != nil {
      return WOPageNameLinkGenerator(associations: &associations)
    }
    if associations["@action"] != nil {
      return WOAtActionLinkGenerator(associations: &associations)
    }

    if let action = associations["action"] {
      /* use WODirectAction for constant action strings! */
      if action.isValueConstant && action.value(in: nil) is String {
        return WODirectActionLinkGenerator(associations: &associations)
      }
      return WOActionLinkGenerator(associations: &associations)
    }
    
    return nil
  }
  
  public static func resourceLinkGenerator(keyedOn key: String,
                                           for associations: inout Bindings)
                       -> WOLinkGenerator?
  {
    if associations[key] != nil {
      return WOHrefLinkGenerator(staticKey: key, associations: &associations)
    }
    if associations["directActionName"] != nil {
      return WODirectActionLinkGenerator(associations: &associations)
    }
    if associations["filename"] != nil {
      return WOFileLinkGenerator(associations: &associations)
    }

    if let action = associations["action"] {
      /* use WODirectAction for constant action strings! */
      if action.isValueConstant && action.value(in: nil) is String {
        return WODirectActionLinkGenerator(associations: &associations)
      }
    }
    
    return nil
  }
  
  public static func containsLinkInAssocations(_ associations: Bindings)
                     -> Bool
  {
    if associations.isEmpty                    { return false }
    if associations["href"]             != nil { return true }
    if associations["directActionName"] != nil { return true }
    if associations["actionClass"]      != nil { return true }
    if associations["pageName"]         != nil { return true }
    if associations["action"]           != nil { return true }
    if associations["@action"]          != nil { return true }
    return false
  }
  

  public init?(associations: inout Bindings) {
    fragmentIdentifier = associations.removeValue(forKey: "fragmentIdentifier")
    queryDictionary    = associations.removeValue(forKey: "queryDictionary")
    sidInURL           = associations.removeValue(forKey: "?wosid")
    
    queryParameters = WOLinkGenerator.extractQueryParameters("?", &associations)
  }
  
  /**
   * This method extract query parameter bindings from a given set of
   * associations. Those bindings start with a question mark (?) followed by
   * the name of the query parameter, eg:
   *
   *     MyLink: WOHyperlink {
   *         directActionName = "doIt";
   *         ?id = 15;
   *     }
   */
  static func extractQueryParameters(_ prefix: String,
                                     _ associations: inout Bindings)
                -> Bindings?
  {
    var extract = Bindings()
    
    for ( key, association ) in associations {
      guard key.hasPrefix(prefix) else { continue }
      extract[key] = association
    }
    
    return extract.isEmpty ? nil : extract
  }
  

  // MARK: - API
  
  open func href(in context: WOContext) -> String? {
    return nil // abstract
  }
  
  /**
   * This is the primary entry point which is called by the respective link
   * element (eg WOHyperlink) to generate the URL which should be generated.
   *
   * @param _ctx - the WOContext to generate the link for
   * @return a String containing the URL represented by this object
   */
  open func fullHref(in context: WOContext) -> String? {
    /* RFC 3986: scheme ":" hier-part [ "?" query ] [ "#" fragment ] */
    
    guard var url = href(in: context) else { return nil }
    
    if !url.contains("?") {
      /* if we have one, its a direct action */
      // TBD: hm, might be a href with query parameters?!
      if let s = buildQueryString(in: context,
                                  withQueryParameterSession: false),
         !s.isEmpty
      {
        url += "?"
        url += s
      }
    }
    
    // FIXME: proper ordering of URL parts ...
    if let fid = fragmentIdentifier?.stringValue(in: context.cursor),
       !fid.isEmpty
    {
      let cs = CharacterSet.urlFragmentAllowed
      url += "#"
      url += fid.addingPercentEncoding(withAllowedCharacters: cs) ?? "" // TBD
    }
    
    return url
  }
  
  /**
   * Calls queryDictionaryInContext() to retrieve the definite map of query
   * parameters for the link object. Then encodes the parameters with proper
   * URL escaping in the response charset.
   *
   * IMPORTANT: this does _not_ include the session-id!
   */
  open func buildQueryString(in context: WOContext,
                             withQueryParameterSession qps: Bool)
            -> String?
  {
    /* Important first step. This retrieves the ?parameters and the
     * queryDictionary binding, etc.
     */
    guard let qp = buildQueryDictionary(in: context,
                                        withQueryParameterSession: qps),
             !qp.isEmpty else {
      return nil
    }

    return qp.stringForQueryDictionary()
  }
  
  open func shouldFormTakeValues(from request: WORequest, in context: WOContext)
            -> Bool
  {
    return true
  }

  /**
   * This method builds a map of all active query parameters in a link. This
   * includes all query session parameters of the context, a possibly bound
   * 'queryDictionary' binding plus all explicitly named "?" query parameters.
   *
   * IMPORTANT: this does *not* include the session-id!
   *
   * Values override each other with
   *
   * - the 'queryDictionary' values override query session values
   * - '?' query bindings override the other two
   *
   * @returns a Map containing the query parameters, or null if there are none
   */
  open func buildQueryDictionary(in context: WOContext,
                                 withQueryParameterSession: Bool = true)
            -> [ String : Any? ]?
  {
    // TODO: implement / port me
    return nil
  }
  
  
  // MARK: - Responder
  
  open func takeValues(from request: WORequest, in ctx: WOContext) throws {
    /* links can take form values !!!! (for query-parameters) */
    
    guard let queryParameters = queryParameters else { return }
    
    // FIXME: This needs "takeValues" support for bulk-setting
    let cursor = ctx.cursor

    // TBD: tolerance level :-)
    for ( key, assoc ) in queryParameters {
      guard assoc.isValueSettableInComponent(cursor) else { continue }
      try? assoc.setValue(request.formValue(for: key), in: cursor)
    }
  }
  
  open func invokeAction(for request: WORequest, in context: WOContext) throws
            -> Any?
  {
    return nil
  }
  
  open func append(to response: WOResponse, in context: WOContext) throws {
    // TBD: who calls this instead of fullHrefInContext? And why does this not
    //      call fullHref...?
    guard var url = href(in: context) else { return }
    
    if !url.contains("?") { /* if we have one, its a direct action */
      if let s = buildQueryString(in: context,
                                  withQueryParameterSession: false),
         !s.isEmpty
      {
        url += "?"
        url += s
      }
    }
    
    // FIXME: proper ordering of URL parts ...
    if let fid = fragmentIdentifier?.stringValue(in: context.cursor),
      !fid.isEmpty
    {
      let cs = CharacterSet.urlFragmentAllowed
      url += "#"
      url += fid.addingPercentEncoding(withAllowedCharacters: cs) ?? "" // TBD
    }
    
    try response.appendContentString(url)
  }
  

  // MARK: - Description
  
  open func appendToDescription(_ ms: inout String) {
    if let v = fragmentIdentifier { ms += " fragment=\(v)" }
    if let v = queryDictionary    { ms += " qd=\(v)"       }
    if let v = queryParameters    { ms += " qp=\(v)"       }
    if let v = sidInURL           { ms += " ?wos=\(v)"     }
  }
  
  
  // MARK: - Regular href links
  
  static let defaultMethod      : WOAssociation =
               WOAssociationFactory.associationWithValue("default")
  static let defaultActionClass : WOAssociation =
               WOAssociationFactory.associationWithKeyPath("context.page.name")!
}

