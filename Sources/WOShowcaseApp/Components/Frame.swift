//
//  Frame.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 30.05.18.
//

import SwiftObjects

@WOComponent final class Frame {
  
  var homepageLink : String? = nil
  
  func awake() {
    
    guard let ctx = context else { return }
    homepageLink = ctx.directActionURLForActionNamed("default")
  }
}

