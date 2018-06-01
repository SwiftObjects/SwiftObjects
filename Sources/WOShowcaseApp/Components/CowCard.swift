//
//  SemanticCard.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 01.06.18.
//

import SwiftObjects

final class CowCard : WOComponent {
  
  var onClick : String?
  var cow     : Cow?
  
  override func awake() {
    super.awake()
    
    expose(clickAction, as: "click")
  }
  
  func clickAction() -> Any? {
    guard let action = onClick else { return nil }
    return performParentAction(action)
  }

}
