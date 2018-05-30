//
//  WOAtActionLinkGenerator.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Generates links which can trigger direct "at" action methods. The basic link
 * scheme is:
 *
 *   /AppName/ActionClass/@ActionName[?parameters[&wosid]]
 *
 * Example:
 *
 *     <wo:a id="double" @action="doDouble" string="double" />
 *
 * The example would call the 'doDouble' method in the page which currently
 * renders the template. The 'id' specifies the element-id (it's also the JS DOM
 * element-id!, you can also set them separately).
 *
 * At actions are a mixture between component actions and direct actions.
 * Like component actions at-actions use the element-id to find the active
 * element on the page.
 * Unlike component actions at-actions do NOT store the context
 * associated with the last page. Instead they embed the name of the page in the
 * URL and reconstruct a fresh instance on the next request.
 * Hence, no state is preserved and element-ids must be crafted more carefully
 * (usually they should be set explicitly).
 */
open class WOAtActionLinkGenerator : WOLinkGenerator {
  
  let action : WOAssociation
  
  override public init?(associations: inout Bindings) {
    guard let action = associations.removeValue(forKey: "@action") else {
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
    guard let page = context.page else {
      context.log.error("WOAtAction generator did not get a page " +
                        "from the context:", self, context)
      return nil
    }
    
    let lda = page.name + "/@" + context.elementID
    let qd = buildQueryDictionary(in: context, withQueryParameterSession: true)
    
    let addSessionID : Bool = {
      guard context.hasSession else { return false }
      if let sidInURL = sidInURL {
        return sidInURL.boolValue(in: context.cursor)
      }
      return context.session.storesIDsInURLs
    }()
    
    return context.directActionURLForActionNamed(lda, with: qd,
                                                 addSessionID: addSessionID,
                                                 includeQuerySession: false)
  }

  /**
   * Invoke the action for the at-action link. Eg this is called by WOHyperlink
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

