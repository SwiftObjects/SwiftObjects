//
//  DemoWOHyperlink.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 31.05.18.
//

import Foundation
import SwiftObjects

final class DemoWOHyperlink : WOComponent {
  
  var counter = 0
  
  let bindingInfo = // for display :-) If only we had reflection ;-)
  """
  var counter = 0
  """.trimmingCharacters(in: .whitespacesAndNewlines)
  
  override func awake() {
    super.awake()
    
    expose(increment, as: "increment")
    expose(decrement, as: "decrement")
    expose(doDouble,  as: "double")
  }
  
  func increment() -> Any {
    counter += 1
    return self
  }
  func decrement() -> Any {
    counter -= 1
    return self
  }
  func doDouble() -> Any {
    counter *= 2
    return self
  }
}
