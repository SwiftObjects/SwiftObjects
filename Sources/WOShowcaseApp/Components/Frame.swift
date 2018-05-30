//
//  Frame.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 30.05.18.
//

import SwiftObjects

class Frame : WOComponent {
  
  var homepageLink : String? = nil
  
  override func awake() {
    super.awake()
    
    guard let ctx = context else { return }
    homepageLink = ctx.directActionURLForActionNamed("default")
  }
}

