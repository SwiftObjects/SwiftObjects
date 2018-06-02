//
//  CowModel.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 01.06.18.
//

final class Cow {
  
  // Those are optional because we use empty cows during the create phase
  var name  : String?
  var body  : String?
  var image : String?
  var friendCount : Int = 0
  
  init(name: String? = nil, body: String? = nil, image: String? = nil,
       friendCount: Int = 0)
  {
    self.name  = name
    self.body  = body
    self.image = image
    self.friendCount = friendCount
  }
  
  var isValid : Bool {
    guard let n = name, !n.isEmpty else { return false }
    
    if let b = body,  !b.isEmpty { return true }
    if let b = image, !b.isEmpty { return true }
    return false
  }
}

final class CowStore {
  
  let urlPrefix = "http://zeezide.com/img/SquareCows/"
  let availableImages = [
    "andreas.jpg",
    "anne.jpg",
    "carmen.jpg",
    "doris.jpg",
    "frieder.jpg",
    "fritz.jpg",
    "gustl.jpg",
    "henriette.jpg",
    "horst.jpg",
    "sowmya.jpg",
    "ulrike.jpg"
  ]
  
  static let shared = CowStore()

  var cows = [
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
        "      \\|________|\n", image: "andreas.jpg", friendCount: 10),
    
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
        "  ^^         ^^           \n", image: "sowmya.jpg", friendCount: 1337),
    
    Cow(name: "beef jerky", body:
        "          (__)\n"     +
        "          (~~)  V\n"  +
        "  /--------\\/   |\n" +
        " * |      | ----:\n"  +
        ">--: |----|\n"        +
        "     |    |\n"        +
        "     ^    ^\n", image: "frieder.jpg", friendCount: 3)
  ]

}
