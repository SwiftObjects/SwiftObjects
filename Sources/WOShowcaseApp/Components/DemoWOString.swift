//
//  DemoWOString.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 31.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import Foundation
import SwiftObjects

@WOComponent final class DemoWOString {
  
  let fourtyTwo = 42
  let pi        = 3.1415
  var hello     = "Hello World"
  let now       = Date()
  let empty     = ""

  let bindingInfo = // for display :-) If only we had reflection ;-)
  """
  let fourtyTwo = 42
  let pi        = 3.1415
  let hello     = "Hello World"
  let now       = Date()
  let empty     = ""
  """.trimmingCharacters(in: .whitespacesAndNewlines)

}
