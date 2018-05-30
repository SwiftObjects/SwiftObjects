//
//  WOComponentRequestHandler.swift
//  SwiftObjects
//
//  Created by Helge Hess on 21.05.18.
//

/**
 * A request handler which invokes actions by restoring a page from a WOContext
 * contained in a WOSession, and then using `invokeAction()` to find the
 * originating action element using its elementID.
 *
 * Note: `WOSession` can only hold so many contexts, so URLs will become invalid
 * over time resulting in the "you have backtracked too far" issue.
 *
 * The Go URL for a component action looks like this:
 *
 *     /AppName/wo/SESSION-ID/CONTEXT-ID/ELEMENT-ID
 *
 * This is different to SOPE (and WO?) where the context-id is stored as part
 * of the element-id.
 */
open class WOComponentRequestHandler : WORequestHandler {

  open var application : WOApplication
  let log : WOLogger
  
  public init(application: WOApplication) {
    self.application = application
    self.log         = application.log
  }
  
  open func handleRequest(_ request: WORequest, in context: WOContext,
                          session: WOSession?) throws -> WOResponse?
  {
    let ctxApp      = context.application
    let response    = context.response
    let handlerPath = request.requestHandlerPathArray
    guard handlerPath.count >= 2 else {
      log.error("malformed component action URL:", request.uri)
      response.status = 400
      return response
    }
    
    let sessionId = handlerPath[0]
    let contextId = handlerPath[1]
    
    /* Note: we allow a non-element id. This will just return the page
     * associated with the context-id as is.
     */
    if handlerPath.count > 2 {
      context.setRequestSenderID(handlerPath[2])
    }

    var rqSession : WOSession
    if let session = session {
      guard session.sessionID == sessionId else {
        log.warn("session ID mismatch component action URL:", sessionId)
        context.response.status = 400
        return context.response
      }
      rqSession = session
    }
    else {
      guard let session = ctxApp.restoreSession(with: sessionId,
                                                in: context) else {
        log.warn("could not restore component action session:", sessionId)
        return try ctxApp.handleSessionRestorationError(in: context)?
          .generateResponse()

      }
      rqSession = session
    }
    
    guard let page = rqSession.restorePage(for: contextId) else {
      return ctxApp.handlePageRestorationError(in: context)
    }
    
    context.page = page
    
    try ctxApp.takeValues(from: request, in: context)
    
    let actionResult : Any?
    if context.senderID != nil {
      actionResult = try ctxApp.invokeAction(for: request, in: context)
    }
    else {
      actionResult = nil
    }
    
    if let response = actionResult as? WOResponse {
      return response
    }
    
    let newPage : WOComponent
    
    if let page = actionResult as? WOComponent {
      newPage = page
      context.page = newPage
    }
    else {
      newPage = page
      if actionResult != nil {
        log.warn("Unexpected page request result:", actionResult)
      }
    }
    
    try ctxApp.append(to: response, in: context)

    return context.response
  }

  open func sessionID(from request: WORequest) -> String? {
    return nil /* we do the request thing in the main method */
  }
}
