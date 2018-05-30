//
//  WOValueLinkGenerator.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

open class WOValueLinkGenerator : WOLinkGenerator {
  
  let value : WOAssociation
  
  override public init?(associations: inout Bindings) {
    guard let value = associations.removeValue(forKey: "value") else {
      return nil
    }
    self.value = value
    super.init(associations: &associations)
  }
  
  override open func href(in context: WOContext) -> String? {
    context.log.error("value links are not implemented:", self)
    return nil
  }
}
