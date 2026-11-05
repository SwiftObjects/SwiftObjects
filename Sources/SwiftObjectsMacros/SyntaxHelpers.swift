//
//  SyntaxHelpers.swift
//  SwiftObjectsMacros
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import SwiftSyntax

extension AttributeListSyntax {

  /// Returns the attribute with the given simple name, if present.
  func first(named name: String) -> AttributeSyntax? {
    for element in self {
      guard case .attribute(let attribute) = element else { continue }
      let typeName = attribute.attributeName.trimmedDescription
      if typeName == name || typeName.hasSuffix("." + name) {
        return attribute
      }
    }
    return nil
  }
}

extension AttributeSyntax {

  /// The arguments of the attribute, empty if there are none.
  var argumentList : LabeledExprListSyntax {
    return arguments?.as(LabeledExprListSyntax.self) ?? []
  }
}

extension ExprSyntax {

  /// The value of the expression if it is a boolean literal.
  var booleanLiteral : Bool? {
    guard let literal = self.as(BooleanLiteralExprSyntax.self) else {
      return nil
    }
    return literal.literal.tokenKind == .keyword(.true)
  }

  /// The value of the expression if it is a plain string literal.
  var stringLiteral : String? {
    guard let literal = self.as(StringLiteralExprSyntax.self) else {
      return nil
    }
    var value = ""
    for segment in literal.segments {
      guard case .stringSegment(let s) = segment else { return nil }
      value += s.content.text
    }
    return value
  }
}
