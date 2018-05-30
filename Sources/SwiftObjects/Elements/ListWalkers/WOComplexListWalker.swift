//
//  WOComplexListWalker.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Concrete subclass of WOListWalker, which can process all possible bindings.
 *
 * Do not instantiate directly, use the WOListWalker.newListWalker() factory
 * function.
 *
 * Bindings:
 * ```
 *   list       [in]  - WOListWalkable
 *   count      [in]  - int
 *   item       [out] - object
 *   index      [out] - int
 *   index1     [out] - int (like index, but starts at 1, not 0)
 *   startIndex [in]  - int
 *   identifier [in]  - string (TODO: currently unescaped)
 *   sublist    [in]  - WOListWalkable
 *   isEven     [out] - boolean
 *   isFirst    [out] - boolean
 *   isLast     [out] - boolean
 *   filter     [in]  - EOQualifier/String
 *   sort       [in]  - EOSortOrdering/EOSortOrdering[]/Comparator/String/bool
 * ```
 */
public struct WOComplexListWalker : WOListWalker, SmartDescription {
  
  let list       : WOAssociation?
  let item       : WOAssociation?
  let sublist    : WOAssociation?
  let count      : WOAssociation?
  let filter     : WOAssociation?
  let sort       : WOAssociation?
  let index      : WOAssociation?
  let index1     : WOAssociation?
  let startIndex : WOAssociation?
  let identifier : WOAssociation?
  let isEven     : WOAssociation?
  let isFirst    : WOAssociation?
  let isLast     : WOAssociation?

  public init(bindings: inout Bindings) {
    self.list       = bindings.removeValue(forKey: "list")
    self.item       = bindings.removeValue(forKey: "item")
    self.sublist    = bindings.removeValue(forKey: "sublist")
    self.count      = bindings.removeValue(forKey: "count")
    self.filter     = bindings.removeValue(forKey: "filter")
    self.sort       = bindings.removeValue(forKey: "sort")
    self.index      = bindings.removeValue(forKey: "index")
    self.index1     = bindings.removeValue(forKey: "index1")
    self.startIndex = bindings.removeValue(forKey: "startIndex")
    self.identifier = bindings.removeValue(forKey: "identifier")
    self.isEven     = bindings.removeValue(forKey: "isEven")
    self.isFirst    = bindings.removeValue(forKey: "isFirst")
    self.isLast     = bindings.removeValue(forKey: "isLast")
  }
  
  /**
   * Determines the List to walk from the bindings and then calls walkList()
   * with that list.
   * This is the primary entry method called by WODynamicElement objects.
   *
   * It first checks the 'list' binding and if this is missing falls back to the
   * 'count' binding.
   */
  public func walkList(in    context   : WOContext,
                       using operation : WOListWalker.WOListWalkerOperation)
                throws
  {
    // TODO: support just "count"! (non-list)
    
    guard let oList = list?.value(in: context.cursor) else { return }
    guard let wList = oList as? WOListWalkable else {
      context.log.error("Could not convert to List to walkable", oList, self)
      return
    }
    
    // TODO: support filter/sort (just wrap iterator?? Needs ZeeQL.Control)
    
    try walkList(wList, using: operation, in: context)
  }
  
  public func invokeAction(for request  : WORequest,
                           on  template : WOElement,
                           in  context  : WOContext) throws -> Any?
  {
    // TODO: support just "count"! (non-list)
    
    guard let oList = list?.value(in: context.cursor) else { return nil }
    guard let wList = oList as? WOListWalkable else {
      context.log.error("Could not convert to List to walkable", oList, self)
      return nil
    }
    
    // TODO: support filter/sort (just wrap iterator?? Needs ZeeQL.Control)

    return try invokeAction(iterating: wList, for: request, on:template,
                            in: context)
  }

  /**
   * The primary worker method. It keeps all the bindings in sync prior invoking
   * the operation.
   */
  public func walkList(_     list      : WOListWalkable,
                       using operation : WOListWalker.WOListWalkerOperation,
                       in    context   : WOContext) throws
  {
    let cursor = context.cursor
    let ( aCount, iterator ) = list.listIterate()
    
    /* limits */
    
    let startIdx = startIndex?.intValue(in: cursor) ?? 0
    let goCount  = count?.intValue(in: cursor) ?? (aCount - startIdx)
    if goCount < 1 { return }
    
    /* start */
    
    if identifier == nil {
      if startIdx == 0 { context.appendZeroElementIDComponent()    }
      else             { context.appendElementIDComponent(startIdx)}
    }
    
    // TODO: Go has another version of this
    let goUntil = (aCount > (startIdx + goCount)) ? startIdx + goCount : aCount
    
    /* repeat */
    
    for cnt in startIdx..<goUntil {
      let lItem = iterator.next()
      
      // FIXME: bundles sets for Swift in takeValues!!
      if let a = index  { try? a.setIntValue(cnt,     in: cursor) }
      if let a = index1 { try? a.setIntValue(cnt + 1, in: cursor) }
      if let a = item   { try? a.setValue   (lItem,   in: cursor) }

      if let a = isFirst {
        if      cnt == startIdx     { try? a.setBoolValue(true,  in: cursor) }
        else if cnt == startIdx + 1 { try? a.setBoolValue(false, in: cursor) }
      }
      if let a = isLast {
        if      cnt + 1 == goUntil { try? a.setBoolValue(true,  in: cursor) }
        else if cnt == startIdx    { try? a.setBoolValue(false, in: cursor) }
      }
      if let a = isEven {
        /* we start even/odd counting at our for loop, not at the idx[0] */
        try? a.setBoolValue(((cnt - startIdx + 1) % 2 == 0), in: cursor)
      }

      if let identifier = identifier {
        context.log.error("got no identifier for item:", item, self)
        let ident = identifier.stringValue(in: cursor) ?? "MISS"
        context.appendElementIDComponent(ident)
      }
      
      /* perform operation for item */

      try operation(cnt, lItem, context)
      
      /* append sublists */
      
      if let sublist = sublist,
         let subWList = listForValue(sublist.value(in: cursor))
      {
        // FIXME: this is going to confuse isFirst/isLast due to the set-optim.
        try walkList(subWList, using: operation, in: context)
      }
      
      /* cleanup */
      
      if identifier != nil { context.deleteLastElementIDComponent()    }
      else                 { context.incrementLastElementIDComponent() }
    }
    
    /* tear down */
    
    if identifier == nil { context.deleteLastElementIDComponent() }
  }
  
  public func invokeAction(iterating list: WOListWalkable,
                           for request  : WORequest,
                           on  template : WOElement,
                           in  context  : WOContext) throws -> Any?
  {
    // FIXME: consolidate this implementation w/ the one above (marked DIFF)
    // Also: SOPE can do this by 'consuming' IDs from the sender, instead of
    //       having to iterate them (i.e. peek into the index of the list).
    //       Though we could also just do this using a prefix match, and then
    //       the next component.
    let cursor = context.cursor
    let ( aCount, iterator ) = list.listIterate()
    
    /* limits */
    
    let startIdx = startIndex?.intValue(in: cursor) ?? 0
    let goCount  = count?.intValue(in: cursor) ?? (aCount - startIdx)
    if goCount < 1 { return nil } // DIFF
    
    /* start */
    
    if identifier == nil {
      if startIdx == 0 { context.appendZeroElementIDComponent()    }
      else             { context.appendElementIDComponent(startIdx)}
    }
    
    // TODO: Go has another version of this
    let goUntil = (aCount > (startIdx + goCount)) ? startIdx + goCount : aCount
    
    /* repeat */
    
    for cnt in startIdx..<goUntil {
      let lItem = iterator.next()
      
      // FIXME: bundles sets for Swift in takeValues!!
      if let a = index  { try? a.setIntValue(cnt,     in: cursor) }
      if let a = index1 { try? a.setIntValue(cnt + 1, in: cursor) }
      if let a = item   { try? a.setValue   (lItem,   in: cursor) }

      if let a = isFirst {
        if      cnt == startIdx     { try? a.setBoolValue(true,  in: cursor) }
        else if cnt == startIdx + 1 { try? a.setBoolValue(false, in: cursor) }
      }
      if let a = isLast {
        if      cnt + 1 == goUntil { try? a.setBoolValue(true,  in: cursor) }
        else if cnt == startIdx    { try? a.setBoolValue(false, in: cursor) }
      }
      if let a = isEven {
        /* we start even/odd counting at our for loop, not at the idx[0] */
        try? a.setBoolValue(((cnt - startIdx + 1) % 2 == 0), in: cursor)
      }

      if let identifier = identifier {
        context.log.error("got no identifier for item:", item, self)
        let ident = identifier.stringValue(in: cursor) ?? "MISS"
        context.appendElementIDComponent(ident)
      }
      
      /* perform operation for item */
      
      // TODO: This is somehwat incorrect, a matched action might indeed return
      //       null! (match marker in context?)
      if let result = try template.invokeAction(for: request, in: context) {
        return result
      }

      /* append sublists */
      
      if let sublist = sublist,
         let subWList = listForValue(sublist.value(in: cursor))
      {
        // FIXME: this is going to confuse isFirst/isLast due to the set-optim.
        if let result = try invokeAction(iterating: subWList, for: request,
                                         on: template, in: context)
        {
          return result
        }
      }
      
      /* cleanup */
      
      if identifier != nil { context.deleteLastElementIDComponent()    }
      else                 { context.incrementLastElementIDComponent() }
    }
    
    /* tear down */
    
    if identifier == nil { context.deleteLastElementIDComponent() }
    return nil
  }

  
  // MARK: - Description

  public func appendToDescription(_ ms: inout String) {
    WODynamicElement.appendBindingsToDescription(&ms,
      "identifier", identifier,
      "list",    list,    "item",    item,
      "sublist", sublist, "count",   count,   "filter", filter, "sort", sort,
      "index",   index,   "index1",  index1,  "startIndex", startIndex,
      "isEven",  isEven,  "isFirst", isFirst, "isLast", isLast
    )
  }
}
