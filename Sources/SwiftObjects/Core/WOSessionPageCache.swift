//
//  WOSessionPageCache.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

open class WOSessionPageCache {
  // FIXME: make LRU, expire pages ...
  
  var storage = [ String : WOComponent ]()
  
  open func containsContextID(_ id: String) -> Bool {
    return storage[id] != nil
  }
  
  open func restorePage(for contextID: String) -> WOComponent? {
    guard let page = storage[contextID] else { return nil }
    // TODO: touch page entry
    
    /* ensure that the page does not refer to a context */
    page.context = nil
    return page
  }
  
  open func savePage(_ page: WOComponent, for contextID: String) {
    storage[contextID] = page
  }
}
