//
//  WOActionMacro.swift
//  SwiftObjectsMacros
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/**
 * Implements the `@WOAction` marker macro.
 *
 * The attribute itself generates no code, it is picked up by the class
 * macros. The expansion only validates the placement of the attribute.
 */
public struct WOActionMacro : PeerMacro {

  public static func expansion(of node: AttributeSyntax,
                               providingPeersOf declaration:
                                 some DeclSyntaxProtocol,
                               in context: some MacroExpansionContext) throws
                     -> [ DeclSyntax ]
  {
    guard let function = declaration.as(FunctionDeclSyntax.self) else {
      context.diagnose(Diagnostic(
        node: node,
        message: MacroExpansionErrorMessage(
          "'@WOAction' can only be applied to methods")))
      return []
    }
    _ = WOActionMethod(function, in: context) // reports placement errors
    return []
  }
}
