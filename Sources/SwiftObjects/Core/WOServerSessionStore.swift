//
//  WOServerSessionStore.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * WOServerSessionStore
 *
 * This class keeps session in-memory.
 *
 * Note: we just keep the live object. I think WO serializes the session which
 *       loweres memory requirements (because only persistent values are saved)
 *       and improves persistent store interoperability.
 *
 * THREAD: the overridden operations are not threadsafe, but thread safety
 *         is accomplished by the checkout/checkin mechanism implemented in
 *         the superclass.
 */
open class WOServerSessionStore : WOSessionStore {
  
  // TODO: reconsider wrt Codable
  
  let lock    = NSLock()
  var storage = [ String : WOSession ]()
  
  open func saveSession(in context: WOContext) {
    guard context.hasSession else { return }
    
    let sid = context.session.sessionID
    
    lock.lock()
    storage[sid] = context.session
    lock.unlock()
  }
  
  open func removeSession(with id: String) -> WOSession? {
    let session : WOSession?
    lock.lock()
    session = storage.removeValue(forKey: id)
    lock.unlock()
    return session
  }
  
  open func restoreSession(for id: String,
                           from request: WORequest) -> WOSession?
  {
    let session : WOSession?
    lock.lock()
    session = storage[id]
    lock.unlock()
    return session
  }
}
