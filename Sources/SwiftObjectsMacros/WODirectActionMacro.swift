//
//  WODirectActionMacro.swift
//  SwiftObjectsMacros
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros

/**
 * Implements the `@WODirectAction` macro.
 *
 * The macro adds the conformance to `WODirectAction`, the storage and the
 * initializer the protocol requires, the lookup of the action methods and
 * KVC accessors for the properties of the class.
 */
public struct WODirectActionMacro : MemberMacro, ExtensionMacro {

  public static func expansion(of node: AttributeSyntax,
                               providingMembersOf declaration:
                                 some DeclGroupSyntax,
                               conformingTo protocols: [ TypeSyntax ],
                               in context: some MacroExpansionContext) throws
                     -> [ DeclSyntax ]
  {
    guard let expansion = WOActionClass(declaration, attribute: node,
                                        kind: .directAction,
                                        conformingTo: protocols, in: context)
    else { return [] }
    return expansion.members()
  }

  public static func expansion(of node: AttributeSyntax,
                               attachedTo declaration: some DeclGroupSyntax,
                               providingExtensionsOf type:
                                 some TypeSyntaxProtocol,
                               conformingTo protocols: [ TypeSyntax ],
                               in context: some MacroExpansionContext) throws
                     -> [ ExtensionDeclSyntax ]
  {
    return try WOActionClass.conformance(of: type, attachedTo: declaration,
                                         to: protocols)
  }
}

/**
 * Implements the `@WOComponent` macro.
 *
 * The macro adds the conformance to `WOComponent`, the storage and the
 * initializer the protocol requires, the lookup of the action methods and
 * KVC accessors for the properties of the class.
 *
 * `lookupActionNamed(_:)` covers all actions and is used by template
 * bindings like `action="$save"`, `lookupDirectActionNamed(_:)` only covers
 * the direct actions, the methods with the `Action` suffix and the ones
 * marked with `@WOAction(direct: true)`. Only those can be invoked using a
 * URL.
 */
