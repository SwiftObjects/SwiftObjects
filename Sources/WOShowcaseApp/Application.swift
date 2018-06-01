//
//  Application.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import SwiftObjects
import jQuery
import SemanticUI

final class WOShowcaseApp : WOApplication {

  override init() {
    super.init()
    
    contextClass = Context.self
    sessionClass = Session.self
    
    let rm = WODevResourceManager(sourceType: WOShowcaseApp.self,
                                  defaultFramework: "WOShowcaseApp")
    rm.register(
      Session.self,
      Context.self,
      DirectAction.self,
      
      Main.self,
      Frame.self,
      DynamicElementSample.self,
      ComponentBindingInfo.self,
      
      DemoWOString.self,
      DemoWOHyperlink.self,
      DemoWORepetition.self
    )
    
    rm.expose(.init("jQuery.min.js",    jQuery.data_jquery_min_js),
              .init("semantic.min.js",  SemanticUI.data_semantic_min_js),
              .init("semantic.min.css", SemanticUI.data_semantic_min_css))
    
    resourceManager = rm
  }
}
