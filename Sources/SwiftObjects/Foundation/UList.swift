//
//  UList.swift
//  SwiftObjects
//
//  Created by Helge Hess on 03.06.18.
//

/**
 * Utility functions. Non-Swifty :-)
 */
public enum UList {
  
  static func contains(_ list: Any, _ item: Any) -> Bool {
    // TODO. This is utter crap, also check `UObject.isEqual` :-)
    guard let ulc = list as? UListContainer else { return false }
    return ulc.ulcContains(item)
  }
  
}

fileprivate protocol UListContainer {
  
  func ulcContains(_ item: Any) -> Bool
  
}

extension Array : UListContainer {
  func ulcContains(_ item: Any) -> Bool { // OMG OMG OMG
    return contains(where: { UObject.isEqual($0, item) })
  }
}

extension Set : UListContainer {
  func ulcContains(_ item: Any) -> Bool { // OMG OMG OMG
    return contains(where: { UObject.isEqual($0, item) })
  }
}
