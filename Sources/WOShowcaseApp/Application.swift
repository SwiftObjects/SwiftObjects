//
//  WOShowcaseApp.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

import SwiftObjects
import jQuery
import SemanticUI

@main
final class WOShowcaseApp : WOApplication {

  override init() {
    super.init()
    
    // Component, direct action, session and context classes are found by
    // name, no registration necessary.
    let rm = WODevResourceManager(sourceType: WOShowcaseApp.self)
    rm.expose(.init("jQuery.min.js",    jQuery.data_jquery_min_js),
              .init("semantic.min.js",  SemanticUI.data_semantic_min_js),
              .init("semantic.min.css", SemanticUI.data_semantic_min_css))
    
    resourceManager = rm
  }
  
  static func main() {
    let WOApp  = WOShowcaseApp()
    let server = WONIOAdaptor(application: WOApp)
    server.listenAndWait()
  }
}
