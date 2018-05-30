//
//  WOHrefLinkGenerator.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * This class manages the generation of 'static links'. The links are not
 * really static because we can still add query parameters, session ids and
 * such.
 */
open class WOHrefLinkGenerator : WOLinkGenerator {
  
  let href : WOAssociation
  
  public init?(staticKey: String, associations: inout Bindings) {
    guard let href = associations.removeValue(forKey: staticKey) else {
      return nil
    }
    self.href = href
    
    super.init(associations: &associations)
  }
  
  override open func href(in context: WOContext) -> String? {
    return href.stringValue(in: context.cursor)
  }
  
  /**
   * Checks whether a WOForm should call takeValuesFromRequest() on its
   * subtemplate tree.
   *
   * The WOHrefLinkGenerator implementation of this method returns true if the
   * request HTTP method is "POST".
   */
  override open func shouldFormTakeValues(from request: WORequest,
                                          in context: WOContext) -> Bool
  {
    return "POST" == request.method
  }
  
  /**
   * Generate the URL for the link by adding queryString, session parameters,
   * fragments etc, if specified.
   *
   * Note: this method only adds the session-id if explicitly specified by the
   *       ?wosid binding.
   */
  override open func fullHref(in context: WOContext) -> String? {
    // TODO: implement / port me
    // For `href` this has other semantics than for dynamic stuff!
    return super.fullHref(in: context)
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    ms += " href=\(href)"
  }
}
