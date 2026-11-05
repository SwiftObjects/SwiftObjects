//
//  WOProperty.swift
//  SwiftObjectsMacros
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import SwiftSyntax

/// Describes a property of the class which is accessible using KVC.
struct WOProperty {

  let name       : String
  let isSettable : Bool

  /**
   * Collects the instance properties declared in the body of the class.
   * Computed properties are included, they are settable if they have a
   * setter. Stored properties with observers are settable. Properties with
   * a `_` prefix are considered private.
   */
  static func properties(in classDecl: ClassDeclSyntax) -> [ WOProperty ] {
    var properties = [ WOProperty ]()

    for member in classDecl.memberBlock.members {
      guard let variable = member.decl.as(VariableDeclSyntax.self) else {
        continue
      }
      let isTypeProperty = variable.modifiers.contains {
        $0.name.tokenKind == .keyword(.static) ||
        $0.name.tokenKind == .keyword(.class)
      }
      guard !isTypeProperty else { continue }
      let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)

      for binding in variable.bindings {
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else { continue }
        let name = pattern.identifier.text
        guard !name.hasPrefix("_") else { continue }

        let isSettable : Bool
        switch binding.accessorBlock?.accessors {
          case .none:
            isSettable = !isLet
          case .getter:
            isSettable = false
          case .accessors(let accessors):
            let kinds = Set(accessors.map { $0.accessorSpecifier.tokenKind })
            let hasGetter = kinds.contains(.keyword(.get))
                         || kinds.contains(.keyword(._read))
                         || kinds.contains(.keyword(.unsafeAddress))
            let hasSetter = kinds.contains(.keyword(.set))
                         || kinds.contains(.keyword(._modify))
                         || kinds.contains(.keyword(.unsafeMutableAddress))
            // observers only (willSet/didSet) => a stored property
            isSettable = hasSetter || !hasGetter
        }
        properties.append(WOProperty(name: name, isSettable: isSettable))
      }
    }
    return properties
  }
}
