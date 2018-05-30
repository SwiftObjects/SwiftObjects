//
//  WOTemplate.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * This is just a simple element wrapper used for the root element of a
 * template. It can transport additional information like the URL the
 * template is living at.
 */
open class WOTemplate : WOElement, SmartDescription {
  
  let log               : WOLogger
  let url               : URL?
  var rootElement       : WOElement? // set by parser
  var subcomponentInfos = [ String : SubcomponentInfo ]()

  struct SubcomponentInfo {
    let componentName : String
    let bindings      : [ String : WOAssociation ]
  }
  
  public init(url: URL?, rootElement: WOElement? = nil,
              log: WOLogger = WOPrintLogger.shared)
  {
    self.log         = log
    self.url         = url
    self.rootElement = rootElement
  }
  
  open func addSubcomponent(with name: String,
                            bindings: [ String : WOAssociation ]) -> String
  {
    let info = SubcomponentInfo(componentName: name, bindings: bindings)
    
    let cname : String = {
      if subcomponentInfos[name] == nil { return name }
      return generateUniqueComponentName(name)
    }()
    
    /* register info */
    subcomponentInfos[cname] = info
    return cname /* return the name we registered the component under */
  }
  
  func generateUniqueComponentName(_ baseName: String) -> String {
    for i in 0..<200 {
      let cname = "\(baseName)[\(i)]"
      if subcomponentInfos[cname] == nil { return cname}
    }
    log.error("could not generate unique component name for:", baseName)
    return baseName
  }
  
  
  /* responder */
  
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    try rootElement?.takeValues(from: request, in: context)
  }
  
  open func invokeAction(for req: WORequest, in ctx: WOContext) throws -> Any? {
    return try rootElement?.invokeAction(for: req, in: ctx)
  }
  
  open func append(to response: WOResponse, in context: WOContext) throws {
    try rootElement?.append(to: response, in: context)
  }
  open func walkTemplate(using walker: WOElementWalker, in context: WOContext)
              throws
  {
    try rootElement?.walkTemplate(using: walker, in: context)
  }

  
  /* description */
  
  open func appendToDescription(_ ms: inout String) {
    if let url = url {
      ms += " url="
      ms += url.absoluteString
    }
    
    if !subcomponentInfos.isEmpty {
      ms += " #subs=\(subcomponentInfos.count)"
    }
  }
}
