//
//  WOElement.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

public protocol WOResponder { // TODO: better name for this
  
  /**
   * Triggers the take-values phase on the WOElement, usually a WOComponent
   * (stateful) or a WODynamicElement (w/o state, retrieves values using
   * bindings). Objects of the latter kind push WORequest form values into the
   * active component using their 'bindings' (WOAssociations).
   *
   * @param _rq  - the request to take values from
   * @param _ctx - the context in which all this happens
   */
  func takeValues(from request: WORequest, in ctx: WOContext) throws
  
  /**
   * Triggers the invoke action phase on the WOElement, usually a WOComponent
   * (stateful) or a WODynamicElement (w/o state, retrieves values using
   * bindings).
   *
   * This method is processed for requests which specify the action in terms of
   * an element id (that is, component actions and at-actions).
   * Direct actions never invoke the invokeAction phase since the URL already
   * specifies the intended target object.
   *
   * @param _rq  - the request to invoke an action for
   * @param _ctx - the context in which all this happens
   * @return the result of the action, usually a WOComponent
   */
  func invokeAction(for request: WORequest, in ctx: WOContext) throws -> Any?
  
  
  /* generating response */
  
  /**
   * Triggers the response generation phase on the WOElement, usually a
   * WOComponent (stateful) or a WODynamicElement (w/o state, retrieves values
   * using bindings).
   *
   * @param _r   - the WOResponse the element should append content to
   * @param _ctx - the WOContext in which the HTTP transaction takes place
   */
  func append(to response: WOResponse, in ctx: WOContext) throws
  
}

/**
 * This is the superclass of either dynamic elements or components. Both types
 * share the same API and can be used together in a template.
 *
 * Dynamic elements are reentrant rendering objects which do not keep own
 * processing state while components do have processing state and most often
 * an associated (own) template.
 *
 * ### Walking
 *
 * Walking is basically a superset of the predefined takeValues/invoke/append
 * methods. It allows you to do arbitrary things with the template structure.
 * Any element which has a subtemplate (a container) should implement the
 * walkTemplate method.
 */
public protocol WOElement : class, WOResponder {

  typealias Bindings = [ String : WOAssociation ]
  
  /**
   * Triggers the take-values phase on the WOElement, usually a WOComponent
   * (stateful) or a WODynamicElement (w/o state, retrieves values using
   * bindings). Objects of the latter kind push WORequest form values into the
   * active component using their 'bindings' (WOAssociations).
   *
   * @param _rq  - the request to take values from
   * @param _ctx - the context in which all this happens
   */
  func takeValues(from request: WORequest, in ctx: WOContext) throws
  
  /**
   * Triggers the invoke action phase on the WOElement, usually a WOComponent
   * (stateful) or a WODynamicElement (w/o state, retrieves values using
   * bindings).
   *
   * This method is processed for requests which specify the action in terms of
   * an element id (that is, component actions and at-actions).
   * Direct actions never invoke the invokeAction phase since the URL already
   * specifies the intended target object.
   *
   * @param _rq  - the request to invoke an action for
   * @param _ctx - the context in which all this happens
   * @return the result of the action, usually a WOComponent
   */
  func invokeAction(for request: WORequest, in ctx: WOContext) throws -> Any?
  
  
  /* generating response */
  
  /**
   * Triggers the response generation phase on the WOElement, usually a
   * WOComponent (stateful) or a WODynamicElement (w/o state, retrieves values
   * using bindings).
   *
   * @param _r   - the WOResponse the element should append content to
   * @param _ctx - the WOContext in which the HTTP transaction takes place
   */
  func append(to response: WOResponse, in ctx: WOContext) throws
  
  /* walking the template */
  
  /**
   * Implemented by classes to check whether the _template needs special
   * processing (eg because its a know subelement, eg a WETableCell inside
   * a WETableView).
   * If not, it should continue down by invoking the _template.walkTemplate()
   * method (which will then call processTemplate() on its template, and so on).
   *
   * @param _cursor   - the current element
   * @param _template - the template (children) of the current element
   * @param _ctx      - the context in which the phase happens
   * @return true if the template walking should continue, false otherwise
   */
  typealias WOElementWalker = ( WOElement, WOElement, WOContext ) throws -> Bool
  
  /**
   * Template walking allows code to trigger custom phases on templates trees.
   * The object implementing the WOElementWalker interface specifies what is
   * supposed to happen in the specific phase.
   * 
   * This object is useful for advanced rendering things, often when you need
   * to collect data before you can run a content generation phase (eg because
   * you need to know the count of the contained objects).
   *
   * @param _walkr - the object implementing the operation of the phase
   * @param _ctx   - the WOContext in which the phase takes place
   */
  func walkTemplate(using walker: WOElementWalker, in ctx: WOContext) throws

}

public extension WOElement {
  
  public
  func takeValues(from request: WORequest, in context: WOContext) throws {}
  
  public
  func invokeAction(for request: WORequest, in ctx: WOContext) throws -> Any? {
    return nil
  }
  
  public
  func append(to response: WOResponse, in context: WOContext) throws {}
  
  public
  func walkTemplate(using walker: WOElementWalker, in context: WOContext) throws {}

}
