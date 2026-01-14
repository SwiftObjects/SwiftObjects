//
//  UList.swift
//  SwiftObjects
//
//  Created by Helge Hess on 03.06.18.
//

public enum UList {

  static func contains(_ list: Any, _ item: Any) -> Bool {
    guard let seq = list as? any Sequence else { return false }
    for element in seq {
      if eq(element, item) { return true }
    }
    return false
  }
}
