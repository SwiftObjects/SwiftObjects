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
  
  public func invokeAction(for request  : WORequest,
                           on  template : WOElement,
                           in  context  : WOContext) throws -> Any?
  {
    guard let oList = list?.value(in: context.cursor) else { return nil }
    guard let wList = oList as? WOListWalkable else {
      context.log.error("Could not convert to List to walkable", oList, self)
      return nil
    }
    
    return try invokeAction(iterating: wList, for: request, on:template,
                            in: context)
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
  
  public func invokeAction(iterating list: WOListWalkable,
                           for request  : WORequest,
                           on  template : WOElement,
                           in  context  : WOContext) throws -> Any?
  {
    // FIXME: consolidate this implementation w/ the one above
    // Also: SOPE can do this by 'consuming' IDs from the sender, instead of
    //       having to iterate them (i.e. peek into the index of the list).
    //       Though we could also just do this using a prefix match, and then
    //       the next component.
    let cursor = context.cursor
    let ( aCount, iterator ) = list.listIterate()
    
    context.appendZeroElementIDComponent()
    defer { context.deleteLastElementIDComponent() }
    
    // TODO: support for cursor
    
    for _ in 0..<aCount {
      let lItem = iterator.next()
      
      if let item = item {
        try? item.setValue(lItem, in: cursor) // TBD
      }
      
      // TODO: This is somehwat incorrect, a matched action might indeed return
      //       null! (match marker in context?)
      if let result = try template.invokeAction(for: request, in: context) {
        return result
      }
      
      context.incrementLastElementIDComponent()
    }

    return nil
  }

  public func appendToDescription(_ ms: inout String) {
    WODynamicElement
      .appendBindingsToDescription(&ms, "list", list, "item", item)
  }
}
