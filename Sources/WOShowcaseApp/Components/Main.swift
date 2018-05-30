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
  
  let componentFileURL = URL(fileURLWithPath: "\(#file)")
  var demos = [ String ]()
  
  public var demo : String? = nil
  
  override func awake() {
    super.awake()

    let fm  = FileManager.default
    let dir = componentFileURL.deletingLastPathComponent()
    demos = ((try? fm.contentsOfDirectory(atPath: dir.path)) ?? [])
            .filter { $0.hasPrefix("Demo") && $0.hasSuffix(".html")  }
            .map    { $0.replacingOccurrences(of: ".html", with: "") }
  }
  
  var demoTitle : String {
    guard let t = demo else { return "" }
    return t.replacingOccurrences(of: "Demo",  with: "")
  }
  
  override func value(forKey k: String) -> Any? {
    switch k { // not having reflection is a pita
      case "demoTitle": return demoTitle
      
      default: return super.value(forKey: k)
    }
  }
}

