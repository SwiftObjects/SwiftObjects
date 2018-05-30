//
//  Session.swift
//  testit
//
//  Created by Helge Hess on 25.05.18.
//

import SwiftObjects

final class Session : WOSession {
  
  override func awake() {
    super.awake()
    
    // in here code can be added when a session is activated.
  }
  
  override func sleep() {
    // in here code can be added that should run before a session persists.
    
    super.sleep()
  }
}
