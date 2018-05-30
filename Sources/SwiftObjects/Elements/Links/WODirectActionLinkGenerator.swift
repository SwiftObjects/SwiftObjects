//
//  WODirectActionLinkGenerator.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Generates links which can trigger direct action methods. The basic link
 * scheme is:
 *
 *     /AppName/ActionClass/ActionName[?parameters[&wosid]]
 *
 */
open class WODirectActionLinkGenerator : WOLinkGenerator {
  
  let directActionName : WOAssociation?
  let action           : WOAssociation?
  let actionClass      : WOAssociation?
  
  override public init?(associations: inout Bindings) {
    let action  = associations.removeValue(forKey: "action")
    actionClass = associations.removeValue(forKey: "actionClass")
      ?? WOLinkGenerator.defaultActionClass
    
    directActionName = associations.removeValue(forKey: "directActionName")
                    ?? action
                    ?? WOLinkGenerator.defaultMethod
    self.action = action
    
    super.init(associations: &associations)
  }
  
  override open func href(in context: WOContext) -> String? {
    guard let directActionName = directActionName else { return nil }
    
    let cursor = context.cursor
    var lda    = directActionName.stringValue(in: cursor)
    
    if let actionClass = actionClass {
      if let lac = actionClass.stringValue(in: cursor), !lac.isEmpty {
        lda = lac + "/" + (lda ?? "default")
      }
    }
    
    let qd = buildQueryDictionary(in: context, withQueryParameterSession: true)
    
    let addSessionID : Bool = {
      guard context.hasSession else { return false }
      if let sidInURL = sidInURL { return sidInURL.boolValue(in: cursor) }
      return context.session.storesIDsInURLs
    }()

    return context.directActionURLForActionNamed(lda ?? "default", // TBD
                                                 with: qd,
                                                 addSessionID: addSessionID,
                                                 includeQuerySession: false)
  }

  override
  open func invokeAction(for request: WORequest, in context: WOContext) throws
              -> Any?
  {
    guard let action = action else {
      context.log.error("direct action link has no action assigned:", self)
      return nil
    }
    
    let cursor = context.cursor
    let result = action.value(in: cursor)
    
    // TODO: explain!
    if let key = result as? String, let component = cursor as? WOComponent {
      return KeyValueCoding.value(forKey: key, inObject: component)
    }
    
    return result
  }

  /**
   * Checks whether a WOForm should call takeValuesFromRequest() on its
   * subtemplate tree.
   *
   * The WODirectActionLinkGenerator implementation of this method asks the
   * page which is active in the given context.
   */
  override open func shouldFormTakeValues(from request: WORequest,
                                          in context: WOContext) -> Bool
  {
    guard let page = context.page else { return false }
    return page.shouldTakeValues(from: request, in: context)
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if let v = directActionName { ms += " da=\(v)"     }
    if let v = actionClass      { ms += " class=\(v)"  }
    if let v = action           { ms += " action=\(v)" }
  }
}
