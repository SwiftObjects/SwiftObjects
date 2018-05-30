//
//  WODirectActionRequestHandler.swift
//  SwiftObjects
//
//  Created by Helge Hess on 21.05.18.
//

import Foundation

/**
 * This handler manages 'direct action' and 'at-action' invocations. It works in
 * either traditional-request handler mode or as a GoCallable.
 *
 * Both variants specify a DA class or a component name in the URL. The handler
 * will instantiate that (eg using pageWithName()) and then call the action on
 * the object.
 *
 * Example URL:
 *
 *     /MyApp/wa/Main/default
 *
 * This will instantiate the "Main" component and call the 'defaultAction'
 * inside the component.
 */
open class WODirectActionRequestHandler : WORequestHandler {
  
  open var application : WOApplication
  let log : WOLogger

  public init(application: WOApplication) {
    self.application = application
    self.log         = application.log
  }
  
  open func handleRequest(_ request: WORequest, in context: WOContext,
                          session: WOSession?) throws -> WOResponse?
  {
    let ( actionClassName, actionName ) = extractActionName(from: request)
    let results : Any?

    guard let rm = context.application.resourceManager else {
      log.error("missing resource manager!", self)
      return nil
    }
    
    if let daClass = rm.lookupDirectActionClass(actionClassName) {
      let da = daClass.init(context: context)
      results = try da.performActionNamed(actionName)
    }
    else if let _ = rm.lookupComponentClass(actionClassName) {
      guard let page = rm.pageWithName(actionClassName, in: context) else {
        log.error("could not instantiate page/action:", actionClassName,
                  "using:", rm)
        return nil
      }
      
      context.page = page
      page.ensureAwake(in: context)
      
      if actionName.hasPrefix("@") {
        /* An element id! (eg @minus or @1.2.3.4). This is a component action
         * w/o the usual page cache.
         */
        let s         = actionName
        let elementID = s[s.index(after: s.startIndex)..<s.endIndex]
        context.setRequestSenderID(String(elementID))
        
        let app = context.application
        if page.shouldTakeValues(from: request, in: context) {
          try app.takeValues(from: request, in: context)
        }
        
        results = try app.invokeAction(for: request, in: context)
               ?? page
      }
      else {
        context.enterComponent(page)
        defer { context.leaveComponent(page) }
        
        let app = context.application
        if page.shouldTakeValues(from: request, in: context) {
          try app.takeValues(from: request, in: context)
        }
        
        // Note: This does *NOT* default to the page. Only @ and component
        //       actions.
        results = try page.performActionNamed(actionName)
      }
    }
    else {
      log.error("did not find action class:", actionClassName, "using:", rm)
      return nil
    }

    return try renderResults(results, in: context)
  }
  
  func extractActionName(from request: WORequest) -> ( String, String ) {
    // TBD: maybe those should return default values
    var actionClassName : String? = nil
    var actionName      : String? = nil
    
    if let s = request.formAction {
      if let idx = s.index(of: "/") {
        actionClassName = String(s[s.startIndex..<idx])
        actionName      = String(s[s.index(after: idx)..<s.endIndex])
      }
      else {
        actionName = s
      }
    }
    
    /* decode URL */
    
    let path = request.requestHandlerPathArray
    switch path.count {
      case 0:
        if actionClassName == nil { actionClassName = "DirectAction" }
        if actionName      == nil { actionName      = "default" }
      
      case 1:
        if actionName != nil {
          /* form name overrides path values */
          if actionClassName == nil { actionClassName = path[0] }
        }
        else {
          actionClassName = "DirectAction"
          actionName      = path[0]
        }
      
      default:
        if actionClassName == nil { actionClassName = path[0] }
        if actionName      == nil { actionName      = path[1] }
    }
    
    /* discard everything after a point, to allow for better download URLs */
    if let s = actionName, let idx = s.index(of: ".") {
      actionName = String(s[s.startIndex..<idx])
    }
    
    return ( actionClassName ?? "DirectAction", actionName ?? "default" )
  }
  
  open func renderResults(_ results: Any?, in context: WOContext) throws
            -> WOResponse?
  {
    if let page = results as? WOComponent {
      context.page = page
      
      page.ensureAwake(in: context)
      context.enterComponent(page)
      defer { context.leaveComponent(page) }
      
      let response = context.response
      try page.append(to: response, in: context)
      return response
    }
    
    if let ar = results as? WOActionResults {
      return try ar.generateResponse()
    }
    
    if let s = results as? String {
      try context.response.appendContentHTMLString(s)
      return context.response
    }
    
    return nil
  }

}
