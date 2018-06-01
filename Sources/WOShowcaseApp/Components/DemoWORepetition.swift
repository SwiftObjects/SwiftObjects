//
//  DemoWORepetition.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 01.06.18.
//

import SwiftObjects

final class DemoWORepetition : WOComponent {
  
    let store       = CowStore.shared
    var selectedCow : Cow? = nil
    var cow         : Cow? = nil // cursor in repetition

    let bindingInfo = // for display :-) If only we had reflection ;-)
    """
    let store       = CowStore.shared
    var selectedCow : Cow? = nil
    var cow         : Cow? = nil
    """

    override func awake() {
        super.awake()
      
        // Use this to expose your methods
        expose(showCowAction, as: "showCow")
    }
    
    func showCowAction() -> Any? {
        selectedCow = cow // the cursor will point to the active cow!
        log.log("selected cow:", cow as Any?)
        return nil // nil means: stay on page, you can also return a new!
    }
  
    var isCowSelected : Bool { return selectedCow === cow }

    // Help out Swift ...
    override func value(forKey k: String) -> Any? {
        if k == "isCowSelected" { return isCowSelected }
        return super.value(forKey: k)
    }
}
