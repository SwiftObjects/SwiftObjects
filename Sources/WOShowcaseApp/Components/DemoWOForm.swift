//
//  DemoWOForm.swift
//  WOShowcaseApp
//
//  Created by Helge Hess on 01.06.18.
//

import SwiftObjects

class DemoWOForm : WOComponent {
  
    let store = CowStore.shared
    var cow   : Cow = Cow()
    var error : String?
    
    let bindingInfo = // for display :-) If only we had reflection ;-)
    """
    let store = CowStore.shared
    var cow   : Cow
    """
    
    var isNew : Bool {
        return store.cows.index(where: { $0 === cow }) == nil
    }
  
    override func awake() {
        super.awake()
      
        // Use this to expose your methods
        expose(saveAction, as: "save")
    }
    
    func saveAction() -> Any? {
        // validation can be done in better ways, but it'll do here
        guard let n = cow.name, !n.isEmpty else {
            error = "A cow needs a proper name!"
            return nil
        }
        guard let b = cow.body, !b.isEmpty else {
            error = "A cow needs some nice body!"
            return nil
        }
      
        if isNew {
            store.cows.append(cow) // insert
            let list = DemoWORepetition()
            list.selectedCow = cow
            return list
        }
      
        // stay on page when we edited an existing cow
        return nil
    }

    // Help out Swift ...
    override func value(forKey k: String) -> Any? {
        if k == "isNew" { return isNew }
        return super.value(forKey: k)
    }
}
