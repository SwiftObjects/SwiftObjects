//
//  DemoWOHyperlink.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 31.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

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
    expose(jumpToStringSample, as: "jumpToStringSample")
  }
  
  func increment() -> WOComponent? {
    counter += 1
    return nil
  }
  func decrement() -> WOComponent? {
    counter -= 1
    return nil
  }
  func doDouble() -> WOComponent? {
    counter *= 2
    return nil
  }
  
  func jumpToStringSample() -> WOComponent? {
    // This is a little like a UIViewController transition.
    let newPage = DemoWOString()
    newPage.hello = "HELLO WORLD" // we can pass over values
    return newPage
  }
}
