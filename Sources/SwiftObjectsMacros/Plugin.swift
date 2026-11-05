//
//  Plugin.swift
//  SwiftObjectsMacros
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftObjectsMacrosPlugin : CompilerPlugin {
  
  let providingMacros : [ Macro.Type ] = [
    WODirectActionMacro.self,
    WOComponentMacro.self,
    WOActionMacro.self
  ]
}
