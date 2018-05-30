//
//  WOResourceURLAssocation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//

open class WOResourceURLAssociation : WOAssociation, SmartDescription {
  
  let filename : String
  
  public init(_ filename: String) {
    self.filename = filename
  }
  
  open var keyPath: String? { return filename }
  
  open var isValueConstant : Bool { return false }
  open var isValueSettable : Bool { return false }

  open func value(in component: Any?) -> Any? {
    return stringValue(in: component)
  }
  
  open func filenameValue(in cursor: Any?) -> String? {
    return filename
  }

  open func stringValue(in cursor: Any?) -> String? {
    let resourceManager : WOResourceManager?
    let context         : WOContext?
    
    if let component = cursor as? WOComponent {
      context = component.context
      resourceManager = component.resourceManager
                     ?? context?.application.resourceManager
    }
    else if let lc = cursor as? WOContext {
      context = lc
      resourceManager = lc.application.resourceManager
    }
    else if let app = cursor as? WOApplication {
      resourceManager = app.resourceManager
      context = nil
    }
    else {
      return nil
    }
    
    guard let filename = filenameValue(in: cursor) else { return nil }
    
    guard let rm = resourceManager, let ctx = context else { return nil }
    return rm.urlForResourceNamed(filename, bundle: nil,
                                  languages: ctx.languages, in: ctx)
  }

  // MARK: - Description
  
  open func appendToDescription(_ ms: inout String) {
    ms += " '\(filename)'"
  }
}

