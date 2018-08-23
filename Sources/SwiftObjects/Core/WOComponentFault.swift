//
//  WOComponentFault.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * This class is used for child components which where not accessed yet. Its
 * required to avoid lookup cycles in the template.
 */
final class WOComponentFault : WOComponent {
  
  var cfName : String? = nil
  
  required init() {
    super.init()
  }
  
  override public var name : String {
    set { cfName = newValue }
    get { return cfName ?? "ERROR:FaultWithoutName" }
  }
  
  // MARK: - Resolve Fault
  
  /**
   * Instantiates the component represented by the fault.
   * The method first retrieves the resource manager associated with the fault,
   * it then attempts to retrieve the resource manager of the parent component.
   * If it got a resource manager, it invokes pageWithName() on it to locate
   * the component and transfers the bindings from the fault to that component.
   *
   * This method is called by WOComponent's childComponentWithName method to
   * replace a fault if it gets used by some template element (usually this is
   * triggered by WOChildComponentReference).
   *
   * @param _parent - the parent component
   * @return the resolved child component, or null if something went wrong
   */
  func resolve(with parent: WOComponent) -> WOComponent? {
    let context = self.context ?? parent.context
    
    /* locate resource manager */
    
    /* Note: Do not call `resourceManager`! It would fallback to the
     *       application resource manager. We want to call the parent RM
     *       if no specific one is assigned */
    // HH: but this is what we do here? :-)
    guard let rm = _resourceManager ?? parent.resourceManager else {
      log.error("got no resource manager for fault resolver:", self)
      return nil
    }
    
    /* make resource manager instantiate the page */
    
    assert(!name.isEmpty, "fault has no name?? \(self)")
    guard let replacement = rm.pageWithName(name, in: context) else {
      log.error("could not resolve fault for component '\(name)'" +
                " in parent:", parent, "\n  using:", rm,
                "\n  in ctx:", context)
      return nil
    }
    
    /* transfer bindings and set parent in new component object */
    
    replacement.wocBindings     = wocBindings
    replacement.parentComponent = parent
    if let context = context {
      replacement.ensureAwake(in: context)
    }
    
    return replacement
  }
  
  
  // MARK: Override some methods which should never be called on a fault

  override public func performActionNamed(_ name: String) -> Any? {
    log.error("called performActionNamed('\(name)') on WOComponentFault!")
    return nil
  }
  
  override
  public func takeValues(from request: WORequest, in context: WOContext) throws
  {
    // TODO: throw
    log.error("called \(#function) on WOComponentFault!")
  }
  
  override public func invokeAction(for request : WORequest,
                                    in  context : WOContext) throws -> Any?
  {
    // TODO: throw
    log.error("called \(#function) on WOComponentFault!")
    return nil
  }
  
  override
  public func append(to response: WOResponse, in context: WOContext) throws {
    // TODO: throw
    log.error("called \(#function) on WOComponentFault!")
  }
  override public func walkTemplate(using walker : WOElementWalker,
                                    in   context : WOContext) throws
  {
    // TODO: throw
    log.error("called \(#function) on WOComponentFault!")
  }
  
  
  // MARK: - Description
  
  override public func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if let n = cfName { ms += " fault=\(n)" }
    else              { ms += " fault"      }
  }
}
