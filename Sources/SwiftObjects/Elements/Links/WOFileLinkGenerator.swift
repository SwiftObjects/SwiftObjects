//
//  WOFileLinkGenerator.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

open class WOFileLinkGenerator : WOLinkGenerator {
  
  let filename  : WOAssociation
  let framework : WOAssociation?

  override public init?(associations: inout Bindings) {
    guard let filename = associations.removeValue(forKey: "filename") else {
      return nil
    }
    self.filename  = filename
    self.framework = associations.removeValue(forKey: "framework")
    super.init(associations: &associations)
  }
  
  override open func href(in context: WOContext) -> String? {
    guard let fn = filename.stringValue(in: context.cursor) else { return nil }
    let fw = framework?.stringValue(in: context.cursor)
    
    guard let rm = context.component?.resourceManager
                ?? context.application.resourceManager else {
      return nil
    }

    return rm.urlForResourceNamed(fn, bundle: fw, languages: context.languages,
                                  in: context)
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    ms += " filename=\(filename)"
    if let a = framework { ms += " framework=\(a)" }
  }
}

