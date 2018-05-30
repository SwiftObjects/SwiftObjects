//
//  DirectAction.swift
//  testit
//
//  Created by Helge Hess on 25.05.18.
//

import SwiftObjects
import SemanticUI

final class DirectAction : WODirectAction {
  
  var age : Int = 1337
  
  required init(context: WOContext) {
    super.init(context: context)
    expose(doIt,     as: "doIt")
    expose(semantic, as: "semantic")
  }
  
  func doIt() -> Any? {
    takeFormValuesForKeys("age")
    return "Hello String World"
  }
  
  override func defaultAction() -> WOActionResults? {
    return pageWithName("Main")
  }
  
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
