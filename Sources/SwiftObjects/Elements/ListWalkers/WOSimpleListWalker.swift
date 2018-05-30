//
//  WOSimpleListWalker.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

public struct WOSimpleListWalker : WOListWalker, SmartDescription {
  
  let list : WOAssociation?
  let item : WOAssociation?
  
  public init(bindings: inout Bindings) {
    self.list = bindings.removeValue(forKey: "list")
    self.item = bindings.removeValue(forKey: "item")
  }
  
  public func walkList(in    context   : WOContext,
                       using operation : WOListWalker.WOListWalkerOperation)
                throws
  {
    guard let oList = list?.value(in: context.cursor) else { return }
    guard let wList = oList as? WOListWalkable else {
      context.log.error("Could not convert to List to walkable", oList, self)
      return
    }
    
    try walkList(wList, using: operation, in: context)
  }
  
  public func walkList(_     list      : WOListWalkable,
                       using operation : WOListWalker.WOListWalkerOperation,
                       in    context   : WOContext) throws
  {
    let cursor = context.cursor
    let ( aCount, iterator ) = list.listIterate()
    
    context.appendZeroElementIDComponent()
    defer { context.deleteLastElementIDComponent() }
    
    // TODO: support for cursor
    
    for i in 0..<aCount {
      let lItem = iterator.next()
      
      if let item = item {
        try? item.setValue(lItem, in: cursor) // TBD
      }
      
      try operation(i, lItem, context)
      
      context.incrementLastElementIDComponent()
    }
  }

  public func appendToDescription(_ ms: inout String) {
    WODynamicElement
      .appendBindingsToDescription(&ms, "list", list, "item", item)
  }
}
