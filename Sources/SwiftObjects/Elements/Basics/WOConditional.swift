//
//  WOConditional.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * Render a subsection or not depending on some component state.
 *
 * Sample:
 *
 *     ShowIfRed: WOConditional {
 *         condition = currentColor;
 *         value     = "red";
 *     }
 *
 * Renders:
 *
 *     This element does not render anything.
 *
 * Bindings:
 * ```
 *   condition   [in] - boolean or object if used with value binding
 *   negate      [in] - boolean
 *   value/v     [in] - object
 *   match       [in] - object (Pattern or Matcher or Pattern-String)
 *   q/qualifier [in] - EOQualifier to be used as condition
 *   not         [in] - boolean (sets condition/negate=true)
 * ```
 *
 * WOConditional is an aliased element:
 *
 *    <wo:if var:value="obj.isTeam">...</wo:if>
 *
 */
open class WOConditional : WODynamicElement {
  
  let condition : WOQualifierEvaluation
  let template  : WOElement? // not really optional, makes no sense?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    let condition = WOComplexCondition(bindings: &bindings)
    self.condition = condition.optimize()
    
    self.template  = WOConditional
                     .processMultiStack(bindings: &bindings, template: template)
    
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  static func processMultiStack(bindings: inout Bindings, template: WOElement?)
              -> WOElement?
  {
    // TODO: port multi stack bindings (key0, value0, negate0)
    return template
  }
  
  
  // MARK: - Evaluate
  
  func doShow(in context: WOContext) -> Bool {
    return condition.evaluateWithObject(context)
  }
  
  
  // MARK: - Responder

  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    guard let template = template, doShow(in: context) else { return }
    
    context.appendElementIDComponent("1")
    defer { context.deleteLastElementIDComponent() }
    
    try template.takeValues(from: request, in: context)
  }
  
  override
  open func invokeAction(for request: WORequest, in context: WOContext) throws
            -> Any?
  {
    guard let template = template, doShow(in: context) else { return nil }
    
    context.appendElementIDComponent("1")
    defer { context.deleteLastElementIDComponent() }
    
    return try template.invokeAction(for: request, in: context)
  }
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard let template = template, doShow(in: context) else { return }
    
    context.appendElementIDComponent("1")
    defer { context.deleteLastElementIDComponent() }
    
    try template.append(to: response, in: context)
  }
  
  override
  open func walkTemplate(using walker: WOElementWalker, in context: WOContext)
              throws
  {
    guard let template = template, doShow(in: context) else { return }

    context.appendElementIDComponent("1")
    defer { context.deleteLastElementIDComponent() }
    
    _ = try walker(self, template, context)
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    ms += " condition=\(condition)"
    if template == nil { ms += " NO-TEMPLATE" }
  }
  
  
  // MARK: - Conditions
  
  struct WOConstCondition : WOQualifierEvaluation, SmartDescription {
    
    let doShow : Bool
    
    init(doShow: Bool) { self.doShow = doShow }
    
    public func evaluateWithObject(_ object: Any?) -> Bool { return doShow }
    
    public func appendToDescription(_ ms: inout String) {
      ms += doShow ? " show" : " hide"
    }
  }
  
  struct WOCheckCondition : WOQualifierEvaluation, SmartDescription {
    
    let condition : WOAssociation
    let doNegate  : Bool

    public init(condition: WOAssociation, doNegate: Bool) {
      self.condition = condition
      self.doNegate  = doNegate
    }
    
    public func evaluateWithObject(_ object: Any?) -> Bool {
      let context  = object as? WOContext
      let cursor   = context != nil ? context?.cursor : context
      
      let doShow = condition.boolValue(in: cursor)
      return doNegate ? !doShow : doShow
    }
    
    public func appendToDescription(_ ms: inout String) {
      ms += " "
      if doNegate { ms += "!" }
      ms += "condition=\(condition)"
    }
  }
  
  struct WOComplexCondition : WOQualifierEvaluation, SmartDescription {
    
    let condition : WOAssociation?
    let negate    : WOAssociation?
    let value     : WOAssociation?
    let match     : WOAssociation?

    public init(bindings: inout Bindings) {
      var condition : WOAssociation?
      var negate    : WOAssociation?
      var value     : WOAssociation?
      var match     : WOAssociation?
      
      condition = bindings.removeValue(forKey: "condition")
      negate    = bindings.removeValue(forKey: "negate")
      value     = bindings.removeValue(forKey: "value")
      match     = bindings.removeValue(forKey: "match")
      
      if value == nil { value = bindings.removeValue(forKey: "v") }
      
      /* <wo:if not="..."> shortcut */
      
      if negate == nil && condition == nil,
         let n = bindings.removeValue(forKey: "not")
      {
        condition = n
        negate    = WOAssociationFactory.associationWithValue(true)
      }
      
      // TODO: support qualifier association (qualifier/q)
      // => we can do that, but we would need ZeeQL

      /* use 'value' as 'condition' if the latter is not set */
      
      if condition == nil, let v = value {
        condition = v
        value     = nil
      }
      
      // TODO: support match binding (WORegExAssociation)

      self.condition = condition
      self.negate    = negate
      self.value     = value
      self.match     = match
    }

    public func optimize() -> WOQualifierEvaluation {
      guard value == nil && match == nil, let condition = condition else {
        return self
      }
      guard negate?.isValueConstant ?? true else { return self }
      
      let doNegate = negate?.boolValue(in: nil) ?? false
      
      if condition.isValueConstant {
        let doShow = condition.boolValue(in: nil)
        return WOConstCondition(doShow: doNegate ? !doShow : doShow)
      }
      
      return WOCheckCondition(condition: condition, doNegate: doNegate)
    }
    
    
    public func evaluateWithObject(_ object: Any?) -> Bool {
      guard let condition = condition else { return false }
      
      let context  = object as? WOContext
      let cursor   = context != nil ? context?.cursor : context
      
      var doShow   = false
      var doNegate = false
      
      if let negate = negate {
        doNegate = negate.boolValue(in: cursor)
      }
      
      // TODO: support match
      
      if let value = value {
        let v = value    .value(in: cursor)
        let o = condition.value(in: cursor)
        
        if let v = v, let o = o {
          // TODO: compare. How? :-)
          // FIXME: THIS IS CRAZY STUFF :-)
          // In ZeeQL we have a protocol for dynamic equality
          doShow = String(describing: v) == String(describing: o)
        }
        else if v != nil || o != nil {
          doShow = false
        }
        else { // both nil
          doShow = true
        }
      }
      else {
        doShow = condition.boolValue(in: cursor)
      }
      
      return doNegate ? !doShow : doShow
    }
    
    // MARK: - Description
    
    public func appendToDescription(_ ms: inout String) {
      WODynamicElement.appendBindingsToDescription(&ms,
        "condition", condition,
        "negate",    negate,
        "value",     value,
        "match",     match
      )
    }
  }
}

public protocol WOQualifierEvaluation {
  // This is actually EOQualifierEvaluation, but I don't want to tie to ZeeQL

  func evaluateWithObject(_ object: Any?) -> Bool
  
}
