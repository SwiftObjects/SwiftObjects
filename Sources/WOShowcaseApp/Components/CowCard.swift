//
//  SemanticCard.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 01.06.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

import SwiftObjects

@WOComponent final class CowCard {
  
  var onClick : String?
  var cow     : Cow?
  
  func clickAction() -> Any? {
    guard let action = onClick else { return nil }
    return performParentAction(action)
  }

}
