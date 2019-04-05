//
//  WOSessionStore.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import struct Foundation.TimeInterval

/**
 * Superclass for "session stores". A WOSessionStore manages the WOSession
 * objects which are not in use by requests. It maintains a checkin/checkout
 * queue to ensure that access to the sessions is serialized.
 */
public protocol WOSessionStore {
  
  func saveSession(in context: WOContext)
  func removeSession(with id: String) -> WOSession?
  func restoreSession(for id: String, from request: WORequest) -> WOSession?

  var sessionCheckOutTimeout : TimeInterval { get set }
  
  /**
   * Lock the given session ID for other threads. Its criticial that the session
   * is checked in again.
   *
   * This method wraps restoreSessionForID() which does the actual session
   * restoration. Its called by WOApplication.restoreSessionForID().
   */
  func checkOutSession(for id: String, from request: WORequest) -> WOSession?
  
  /**
   * This is called by WOApplication.saveSessionForContext() to allow other
   * threads to access the session. Remember that session access is
   * synchronized.
   */
  func checkInSession(of context: WOContext)
}

public extension WOSessionStore {

  var sessionCheckOutTimeout : TimeInterval {
    get { return 5000.0 }
    set { /* noop */ }
  }

  func checkOutSession(for id: String, from request: WORequest)
                -> WOSession?
  {
    // FIXME: REMOVE ME, port me
    return restoreSession(for: id, from: request)
  }
  
  func checkInSession(of context: WOContext) {
    // FIXME: REMOVE ME, port me
    saveSession(in: context)
  }
}
