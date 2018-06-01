//
//  WODirectAction.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation
import Runtime

/**
 * A WODirectAction object is pretty much like a servlet, it can accept
 * requests and is responsible for producing a result. The result can be
 * either a WOResponse or a WOComponent or anything else which can be
 * rendered by Go.
 */
open class WODirectAction : WOAction, SmartDescription,
                            KeyValueCodingType, MutableKeyValueCodingType,
                            ExtraVariables, WOActionMapper
{
  public let log                : WOLogger
  open   var context            : WOContext
  open   var variableDictionary = [ String : Any ]()
  public var exposedActions     = [ String : WOActionCallback ]()
  
  public required init(context: WOContext) {
    self.context = context
    self.log     = context.log
    expose(defaultAction, as: "default")
  }
  
  /**
   * Just calls the matching static method which contains the actual
   * implementation. Subclasses can override the instance method to
   * implement a custom behaviour (eg clean up the name prior passing it
   * to the super implementation).
   */
  public func performActionNamed(_ name: String) throws -> Any? {
    defer { exposedActions.removeAll() } // our 'sleep' version to break cycles
    return try WODirectAction.performActionNamed(name, on: self, in: context)
  }
  
  /**
   * Implements the "direct action" request handling / method lookup. This is
   * a static method because its reused by WOComponent.
   *
   * This implementation checks for a method with a name which ends in "Action"
   * and which has no parameters, eg:
   *
   *     defaultAction
   *     viewAction
   *
   * Hence only methods ending in "Action" are exposed (automagically) to the
   * web.
   *
   * @param _o    - the WODirectAction or WOComponent
   * @param _name - the name of the action to invoke
   * @param _ctx  - the WOContext to run the action in
   * @return the result, eg a WOComponent or WOResponse
   */
  public static func performActionNamed(_ name: String, on object: Any,
                                        in context: WOContext) throws -> Any?
  {
    if let actionMapper = object as? WOActionMapper,
       let method = actionMapper.lookupActionNamed(name)
    {
      return try method()
    }
    
    // TODO: do all the extra reflection stuff, e.g. missing methods and such
    let result = KeyValueCoding.value(forKey: name + "Action", inObject: object)
    return result
  }
  
  open func defaultAction() -> WOActionResults? {
    return pageWithName("Main")
  }

  /**
   * Iterates over the given keys and invokes takeValueForKey for each key,
   * using a similiar named form values as the value.
   */
  open func takeFormValueArraysForKeyArray(_ keys : [ String ]) {
    let req = request
    
    var values = [ String : Any? ]()
    for key in keys {
      values[key] = req.formValue(for: key)
    }
    
    try? takeValuesForKeys(values)
  }
  
  open func takeFormValuesForKeys(_ keys : String...) {
    let req = request
    
    var values = [ String : Any? ]()
    for key in keys {
      values[key] = req.formValue(for: key)
    }
    
    try? takeValuesForKeys(values)
  }
  
  
  // MARK: - KVC
  
  lazy var typeInfo = try? Runtime.typeInfo(of: type(of: self))
  
  open func takeValue(_ value : Any?, forKey k: String) throws {
    if variableDictionary[k] != nil {
      if let value = value { variableDictionary[k] = value }
      else { variableDictionary.removeValue(forKey: k) }
    }
    
    switch k {
      case "context", "request",
           "session", "existingSession",
           "variableDictionary", "exposedActions", "self":
        return try handleTakeValue(value, forUnboundKey: k)
      default: break
    }
    
    if exposedActions[k] != nil {
      return try handleTakeValue(value, forUnboundKey: k)
    }
    
    if let ti = typeInfo, let prop = try? ti.property(named: k) {
      var me = self // TBD
      if let value = value { try prop.zset(value: value,        on: &me) }
      else                 { try prop.zset(value: value as Any, on: &me) }
      return
    }
    
    variableDictionary[k] = value
  }
  
  open func value(forKey k: String) -> Any? {
    if let v = variableDictionary[k] { return v }
    
    if let a = exposedActions[k] {
      do {
        let result = try a()
        return result
      }
      catch { // FIXME
        log.error("KVC action failed:", k, "error:", error)
        return nil
      }
    }
    
    switch k {
      case "context":         return context
      case "request":         return request
      case "session":         return session
      case "existingSession": return existingSession
      case "self":            return self
      default: break
    }
    
    guard let ti = typeInfo, let prop = try? ti.property(named: k) else {
      return handleQueryWithUnboundKey(k)
    }
    do {
      // if this is an optional, we wrap it again
      let v = try prop.zget(from: self)
      return v
    }
    catch {
      log.error("Failed to get KVC property:", k, error)
      return nil
    }
  }

  
  // MARK: - Description
  
  open func appendToDescription(_ ms: inout String) {
    ms += " ctx=\(context.contextID)"
    if variableDictionary.count > 0 {
      ms += " #vars=\(variableDictionary.count)"
    }
    if exposedActions.count > 0 {
      ms += " exposes=\(exposedActions.keys)"
    }
  }
}
