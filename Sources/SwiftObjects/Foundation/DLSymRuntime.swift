//
//  DLSymRuntime.swift
//  testit
//
//  Created by Helge Hess on 25.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

func SOGetPackageName<T>(_ type: T.Type, default: String = "") -> String {
  let qualified = _typeName(type, qualified: true)
  if let dotIndex = qualified.firstIndex(of: ".") {
    return String(qualified[..<dotIndex])
  }
  return `default`
}

func SOGetClassByName(_ name: String, _ module: String) -> AnyClass? {
  _typeByName("\(module).\(name)") as? AnyClass
}
