//
//  WOActionLinkGenerator.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * This helper objects manages "WO Component Actions". To generate URLs it
 * calls the WOContext' componentActionURL() method. To trigger the action
 * it just evaluates the 'action' association (since the calling WOElement
 * already checks whether the link should be triggered, eg by comparing the
 * senderID).
 */
open class WOActionLinkGenerator : WOLinkGenerator {
  
  let action : WOAssociation
  
  override public init?(associations: inout Bindings) {
    guard let action = associations.removeValue(forKey: "action") else {
      return nil
    }
    
    if action.isValueConstant, let v = action.value(in: nil) as? String {
      self.action = WOAssociationFactory.associationWithKeyPath(v)!
    }
    else {
      self.action = action
    }
    
    super.init(associations: &associations)
  }
  
  override open func href(in context: WOContext) -> String? {
    return context.componentActionURL()
  }
  
  /**
   * Invoke the action for the action link. Eg this is called by WOHyperlink
   * if its element-id matches the senderid, hence its action should be
   * triggered.
   * Therefore this method just evaluates its associated method (by evaluating
   * the binding, which in turn calls the unary method) and returns the value.
   *
   * @param _rq  - the WORequest representing the call
   * @param _ctx - the active WOContext
   * @return the result of the action
   */
  override
  open func invokeAction(for request: WORequest, in context: WOContext) throws
            -> Any?
  {
    return action.value(in: context.cursor)
  }
  
  /**
   * Checks whether a WOForm should call takeValuesFromRequest() on its
   * subtemplate tree.
   * 
   * This implementation checks whether the senderID() of the WOContext matches
   * the current elementID().
   *
   * @param _rq  - the WORequest containing the form values
   * @param _ctx - the active WOContext
   * @return true if the WOForm should trigger its childrens, false otherwise
   */
  override open func shouldFormTakeValues(from request: WORequest,
                                          in context: WOContext) -> Bool
  {
    return context.elementID == context.senderID
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    ms += " action=\(action)"
  }
}

