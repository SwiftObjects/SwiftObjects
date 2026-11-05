//
//  DemoWOHyperlink.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 31.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import SwiftObjects

@WOComponent final class DemoWOHyperlink {
  
  var counter = 0
  
  let bindingInfo = // for display :-) If only we had reflection ;-)
  """
  var counter = 0
  """.trimmingCharacters(in: .whitespacesAndNewlines)
  
  @WOAction func increment() { counter += 1 }
  @WOAction func decrement() { counter -= 1 }
  @WOAction func double() { counter *= 2 }
  
  @WOAction
  func jumpToStringSample() -> WOComponent? {
    // This is a little like a UIViewController transition.
    let newPage = DemoWOString()
    newPage.hello = "HELLO WORLD" // we can pass over values
    return newPage
  }
}
