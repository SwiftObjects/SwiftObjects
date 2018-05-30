//
//  WORequestHandler.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Abstract superclass for request handlers. Request handlers are objects which
 * decide what to do with a given request. That is, how to decode the URL and
 * how to map the URL to the controller objects.
 *
 * There are four basic request handlers:
 *
 * - WODirectActionRequestHandler
 * - WOComponentRequestHandler
 * - WOResourceRequestHandler
 * - GoObjectRequestHandler
 *
 * Technically the first three are superflous in Go because of the
 * GoObjectRequestHandler. They are left in place for compatibility
 * reasons.
 */
public protocol WORequestHandler {
  
  func handleRequest(_ request: WORequest) throws -> WOResponse?

  func handleRequest(_ request: WORequest, in context: WOContext,
                     session: WOSession?) throws -> WOResponse?
  
  func sessionID(from request: WORequest) -> String?
  
  var restoreSessionsUsingIDs : Bool { get }
  var doesRejectFavicon       : Bool { get }

  var application : WOApplication { get }

  func autocreateSession(in context: WOContext) -> Bool
}

public extension WORequestHandler {

  public func autocreateSession(in context: WOContext) -> Bool {
    return false
  }

  public func sessionID(from request: WORequest) -> String? {
    return request.sessionID
  }

  public var restoreSessionsUsingIDs : Bool { return true }
  public var doesRejectFavicon       : Bool { return true }

  public func handleRequest(_ request: WORequest) throws -> WOResponse? {
    guard !doesRejectFavicon || request.uri != "/favicon.ico" else {
      return nil
    }
    
    let log     = application.log
    let context = application.createContext(for: request)
    
    var sessionId : String? = sessionID(from: request)
    if let sid = sessionId, sid.isEmpty || sid == "nil" { sessionId = nil }
    
    application.awake()
    defer { application.sleep() }
    
    context.awake()
    defer { context.sleep() }
    
    // ugly, cleanup
    var r : WOResponse? = nil
    do {
      var session : WOSession?  = nil
      
      // restore session

      if restoreSessionsUsingIDs {
        func restoreFailed() throws -> WOResponse? {
          let ar = application.handleSessionRestorationError(in: context)
          return try ar?.generateResponse()
        }
        
        if let sid = sessionId {
          session = application.restoreSession(with: sid, in: context)
          if session == nil {
            r = try restoreFailed()
            sessionId = nil
          }
        }
        
        if r == nil && session == nil, autocreateSession(in: context) {
          if !application.refusesNewSessions {
            session = application.initializeSession(in: context)
            if session == nil {
              r = try restoreFailed()
            }
          }
          else {
            r = try restoreFailed()
          }
        }
      }
      
      // run handler
      
      if r == nil {
        r = try handleRequest(request, in: context, session: session)
      }
      
      // save session
      
      if context.savePageRequired {
        if let page = context.page {
          context.session.savePage(page)
        }
        else {
          log.warn("requested save-page, but no page active:", context)
        }
      }
      
      if context.hasSession {
        // TODO: ensure that session gets a sleep?
        _ = application.saveSession(of: context)
      }
    }
    catch {
      let ar = application.handleError(error, in: context)
      r = try ar?.generateResponse()
    }
    
    if r == nil { r = context.response }
    
    /* tear down context */
    // TODO: send sleep() or something to tear it down?
    
    return r
  }
}
