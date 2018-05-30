//
//  main.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation
import SwiftObjects

class Main : WOComponent {
  
  var title = "My First Component"
  
  override func awake() {
    super.awake()
    expose(handlePostAction, as: "handlePost")
  }

  func handlePostAction() -> Any? {
    log.log("POST:", context?.request.formValues)
    log.log("Body:", context?.request.contentString ?? "-")
    // application/x-www-form-urlencoded
    log.log("Body:", context?.request.headers)
    return self
  }
}

