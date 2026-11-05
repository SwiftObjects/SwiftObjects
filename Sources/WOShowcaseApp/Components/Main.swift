//
//  main.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

import Foundation
import SwiftObjects

@WOComponent final class Main {
  
  let componentFileURL = URL(fileURLWithPath: #filePath)
  var demos = [ String ]()
  
  public var demo : String? = nil
  
  func awake() {
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
  
}
