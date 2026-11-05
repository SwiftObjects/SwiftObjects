//
//  DirectAction.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 25.05.18.
//

import SwiftObjects
import SemanticUI

@WODirectAction final class DirectAction {
  
  var age : Int = 1337
  
  @WOAction
  func doIt() -> Any? {
    takeFormValuesForKeys("age")
    return "Hello String World"
  }
  
  func defaultAction() -> WOActionResults? {
    return pageWithName("Main")
  }
  
  @WOAction
  func semantic() -> WOResponse? {
    let r = WOResponse()
    if let ct = WOExtensionToMimeType["css"] {
      r.setHeader(ct, for: "Content-Type")
    }
    
    if let p = request.requestHandlerPath {
      print("RP:", p)
    }
    
    r.setHeader("gzip", for: "Content-Encoding")
    r.contents = SemanticUI.data_semantic_min_css
    return r
  }
}
