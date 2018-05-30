//
//  main.swift
//  testit
//
//  Created by Helge Hess on 25.05.18.
//

import SwiftObjects

let WOApp  = WOShowcaseApp()
let server = WONIOAdaptor(application: WOApp)
server.listenAndWait()
