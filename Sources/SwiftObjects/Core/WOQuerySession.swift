//
//  WOQuerySession.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * This object represents objects which got unarchived from the form values,
 * eg in the query parameters of a string, eg:
 *
 *     /myAction?dg_batchindex=2
 *
 * The query session can be manipulated in templates using the
 * WOChangeQuerySession dynamic element.
 */
open class WOQuerySession {
  /*
   * TBD: document more
   * - usually subclasses and handcoded? (eg display group setup)
   * - why is it a global (WOContext) object instead of component-local
   *   - should the state depend on the component and get unarchived by the comp
   *     - or by the Go callable object?
   *     - well, *session* means those are parameters which are not component/
   *       resource specific. You can still use WOChangeQuerySession to handle
   *       component local things.
   *   - TBD: can we add specific component support?
   *     - ie WOSession can store components based on the context
   */

  var request       : WORequest
  var qpSession     : [ String : Any ]?
  var qpSessionKeys : [ String ]?
  
  public init(context: WOCoreContext) {
    self.request = context.request
  }
  
  // TODO: port me
  
  open var allQuerySessionValues : [ String : Any ] {
    // TODO: port me
    return [:]
  }
  
  open var hasActiveQuerySessionValues : Bool {
    // TODO: port me
    return false
  }
  
  open func add(to queryDictionary: inout [ String : Any? ]) {
    // TODO: port me
  }
}
