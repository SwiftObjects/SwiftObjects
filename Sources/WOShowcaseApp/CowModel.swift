//
//  CowModel.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 01.06.18.
//

import Foundation

final class Cow {
  
  // Those are optional because we use empty cows during the create phase
  var name : String?
  var body : String?
  
  init(name: String? = nil, body: String? = nil) {
    self.name = name
    self.body = body
  }
}

final class CowStore {
  
  static let shared = CowStore()

  var cows : [ Cow ] = [
    // Generated directly from within Xcode using CodeCows:
    //   https://itunes.apple.com/us/app/codecows/id1176112058
    // Also available as an SPM package:
    //   https://github.com/AlwaysRightInstitute/cows
    
    Cow(name: "CompuCow Discovers Bug in Compiler", body:
        "          (__)\n"                     +
        "        /  .\\/.     ______\n"        +
        "       |  /\\_|     |      \\\n"      +
        "       |  |___     |       |\n"       +
        "       |   ---@    |_______|\n"       +
        "    *  |  |   ----   |    |\n"        +
        "     \\ |  |_____\n"                  +
        "      \\|________|\n"),
    
    Cow(name: "This cow jumped over the Moon", body:
        "        o\n"                                                     +
        "        | [---]\n"                                               +
        "        |   |\n"                                                 +
        "        |   |                              |------========|\n"   +
        "   /----|---|\\                             | **** |=======|\n"  +
        "  /___/___\\___\\                         o  | **** |=======|\n" +
        "  |            |                     ___|  |==============|\n"   +
        "  |           |                ___  {(__)} |==============|\n"   +
        "  \\-----------/             [](   )={(oo)} |==============|\n"  +
        "   \\  \\   /  /             /---===--{ \\/ } |\n"               +
        "-----------------         / | NASA  |====  |\n"                  +
        "|               |        *  ||------||-----^\n"                  +
        "-----------------           ||      |      |\n"                  +
        "  /    /  \\   \\             ^^      ^      |\n"                +
        " /     ----    \\\n"                                             +
        "  ^^         ^^           \n"),
    
    Cow(name: "beef jerky", body:
        "          (__)\n"     +
        "          (~~)  V\n"  +
        "  /--------\\/   |\n" +
        " * |      | ----:\n"  +
        ">--: |----|\n"        +
        "     |    |\n"        +
        "     ^    ^\n")
  ]

}
