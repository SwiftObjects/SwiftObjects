//
//  WOPageNameLinkGenerator.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

open class WOPageNameLinkGenerator : WOLinkGenerator {
  
  let pageName : WOAssociation
  
  override public init?(associations: inout Bindings) {
    guard let pageName = associations.removeValue(forKey: "pageName") else {
      return nil
    }
    self.pageName = pageName
    super.init(associations: &associations)
  }
  
  override open func href(in context: WOContext) -> String? {
    return context.componentActionURL()
  }

  override
  open func invokeAction(for request: WORequest, in context: WOContext) throws
              -> Any?
  {
    guard let pn = pageName.stringValue(in: context.cursor) else {
      return nil
    }
    
    return context.application.pageWithName(pn, in: context)
  }
  
  override open func shouldFormTakeValues(from request: WORequest,
                                          in context: WOContext) -> Bool
  {
    return context.elementID == context.senderID
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    ms += " page=\(pageName)"
  }
}
