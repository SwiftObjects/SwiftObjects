//
//  WOPopUpButton.swift
//  SwiftObjects
//
//  Created by Helge Hess on 01.06.18.
//

/**
 * Create HTML form single-selection popups.
 *
 * Sample:
 * ```
 * Country: WOPopUpButton {
 *   name      = "country";
 *   list      = ( "UK", "US", "Germany" );
 *   item      = item;
 *   selection = selectedCountry;
 * }
 * ```
 * Renders:
 * ```
 *   <select name="country">
 *     <option value="UK">UK</option>
 *     <option value="US" selected>US</option>
 *     <option value="Germany">Germany</option>
 *     [sub-template]
 *   </select>
 * ```
 *
 * Bindings (WOInput):
 * ```
 *   id         [in]  - string
 *   name       [in]  - string
 *   value      [io]  - object
 *   readValue  [in]  - object (different value for generation)
 *   writeValue [out] - object (different value for takeValues)
 *   disabled   [in]  - boolean
 * ```
 * Bindings:
 * ```
 *   list              [in]  - List
 *   item              [out] - object
 *   selection         [out] - object
 *   string            [in]  - String
 *   noSelectionString [in]  - String
 *   selectedValue     [out] - String
 *   escapeHTML        [in]  - boolean
 *   itemGroup
 * ```
 *
 * Bindings (WOHTMLElementAttributes):
 * ```
 *   style  [in]  - 'style' parameter
 *   class  [in]  - 'class' parameter
 *   !key   [in]  - 'style' parameters (eg <input style="color:red;">)
 *   .key   [in]  - 'class' parameters (eg <input class="selected">)
 * ```
 */
open class WOPopUpButton : WOInput {
  
  static let WONoSelectionString = "WONoSelectionString"

  let list              : WOAssociation?
  let item              : WOAssociation?
  let selection         : WOAssociation?
  let string            : WOAssociation?
  let noSelectionString : WOAssociation?
  let selectedValue     : WOAssociation?
  let escapeHTML        : WOAssociation?
  let itemGroup         : WOAssociation?
  let formatter         : WOFormatter?
  let template          : WOElement?

  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    list               = bindings.removeValue(forKey: "list")
    item               = bindings.removeValue(forKey: "item")
    selection          = bindings.removeValue(forKey: "selection")
    string             = bindings.removeValue(forKey: "string")
    noSelectionString  = bindings.removeValue(forKey: "noSelectionString")
    selectedValue      = bindings.removeValue(forKey: "selectedValue")
    escapeHTML         = bindings.removeValue(forKey: "escapeHTML")
    itemGroup          = bindings.removeValue(forKey: "itemGroup")
    
    formatter = WOFormatterFactory.formatter(for: &bindings)
    
    self.template = template
    
    super.init(name: name, bindings: &bindings, template: template)
  }

  override
  open func takeValues(from request: WORequest, in context: WOContext) throws {
    let cursor = context.cursor
    
    if let a = disabled, a.boolValue(in: cursor) { return }
    
    let formName = elementName(in: context)
    
    guard let formValue = request.stringFormValue(for: formName) else {
      /* We need to return here and NOT reset the selection. This is because the
       * page might have been invoked w/o a form POST! If we do not, this
       * resets the selection.
       *
       * TODO: check whether HTML forms MUST submit an empty form value for
       *       popups.
       */
      return;
    }

    let isNoSelection = formValue == WOPopUpButton.WONoSelectionString
    
    let objects : WOListWalkable.AnyCollectionIteratorInfo?
    if let list = list {
      objects = listForValue(list.value(in: cursor))?.listIterate()
    }
    else {
      objects = nil
    }
    
    var object : Any? = nil
    
    if let _ = writeValue {
      /* has a 'value' binding, walk list to find object */
      if let ( _, iterator ) = objects {
        let item : WOAssociation? = {
          guard let item = self.item else { return nil }
          return item.isValueSettableInComponent(cursor) ? item : nil
        }()
        
        for lItem in iterator {
          try item?.setValue(lItem, in: cursor)
          
          let cv = readValue?.stringValue(in: cursor)
          if cv == formValue {
            object = lItem
            break
          }
        }
      }
    }
    else if !isNoSelection {
      /* an index binding? */
      let idx = Int(formValue) ?? -1 // hmmm
      if let ( count, iterator ) = objects {
        if idx < 0 || idx >= count {
          context.log.error("popup value out of range:", idx, count, objects)
          object = nil
        }
        else {
          var p = 0
          for lItem in iterator { // sigh
            if p == idx {
              object = lItem
              break
            }
            p += 1
          }
        }
      }
    }
    else {
      context.log.warn("popup has no form value, value binding or selection:",
                       self, formValue)
    }

    /* push selected value */
    
    try selectedValue?.setValue(isNoSelection ? nil : formValue, in: cursor)
    
    /* process selection */
    
    if let a = selection, a.isValueSettableInComponent(cursor) {
      try a.setValue(object, in: cursor)
    }

    /* reset item to avoid dangling references */
    try item?.setValue(nil, in: cursor)
  }
  
  
  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    guard !context.isRenderingDisabled else {
      try template?.append(to: response, in: context)
      return
    }
    
    let cursor = context.cursor
  
    try response.appendBeginTag("select")
  
    if let lid = id?.stringValue(in: cursor) {
      try response.appendAttribute("id", lid)
    }
    
    try response.appendAttribute("name", elementName(in: context))
    
    if let a = disabled, a.boolValue(in: cursor) {
      try response.appendAttribute("disabled",
          context.generateEmptyAttributes ? nil : "disabled")
    }
  
    try coreAttributes?.append(to: response, in: context)
    try appendExtraAttributes(to: response, in: context)
    
    try response.appendBeginTagEnd()
  
    /* content */
  
    try appendOptions(to: response, in: context)
  
    try template?.append(to: response, in: context)

    /* close tag */
  
    try response.appendEndTag("select")
  }
  
  open func appendOptions(to response: WOResponse,
                          in context: WOContext) throws
  {
    guard !context.isRenderingDisabled else { return }

    let cursor          = context.cursor
    let escapesHTML     = escapeHTML?.boolValue(in: cursor) ?? true
    let hasSettableItem = item?.isValueSettableInComponent(cursor) ?? false
    
    /* determine selected object */
    
    var byVal = false
    var sel   : Any? = nil
    
    if selection == nil {
      if let selectedValue = selectedValue {
        byVal = true
        sel   = selectedValue.value(in: cursor)
      }
    }
    else if let selectedValue = selectedValue {
      byVal = true
      sel   = selectedValue.value(in: cursor)
      context.log.warn("both, 'selection' and 'selectedValue' bindings active.",
                       self, selectedValue, selection)
    }
    else {
      sel = selection?.value(in: cursor)
    }
    
    var previousGroup : String? = nil
    
    /* process noSelectionString option */
    
    if let nilStr = noSelectionString?.stringValue(in: cursor) {
      if let itemGroup = itemGroup {
        if hasSettableItem { try item?.setValue(nil, in: cursor) }
        
        if let group = itemGroup.stringValue(in: cursor) {
          try response.appendBeginTag("optgroup")
          try response.appendContentString(" label=\"")
          
          // FIXME: (attr escaping)
          if escapesHTML { try response.appendContentHTMLString(group) }
          else           { try response.appendContentString    (group) }
          try response.appendContentCharacter("\"")
          try response.appendBeginTagEnd()
          
          previousGroup = group
        }
      }
      
      try response.appendBeginTag("option")
      try response.appendAttribute("value", WOPopUpButton.WONoSelectionString)
      try response.appendBeginTagEnd()
      
      if escapesHTML { try response.appendContentHTMLString(nilStr) }
      else           { try response.appendContentString    (nilStr) }
      try response.appendEndTag("option");
      // FIXME (stephane) Shouldn't we set the 'selected' if
      //                  selArray/selValueArray is empty?
    }

    /* loop over options */
    
    var foundSelection = false

    var toGo = 0
    if let list = list,
       let objects = listForValue(list.value(in: cursor))?.listIterate()
    {
      // TBD: should we process this using the list
      toGo = objects.count
      
      var i = 0
      for object in objects.iterator {
        if hasSettableItem { try item?.setValue(object, in: cursor) }
        
        /* determine value (DUP below) */
  
        let v  : Any?
        let vs : String?
        if let readValue = readValue {
          v  = readValue.value(in: cursor)
          if let v = v { vs = String(describing: v) }
          else         { vs = nil }
        }
        else {
          vs = String(i) // adds the repetition index as the value!
          v  = vs;
        }
  
        /* determine selection (compare against value or item) */
        
        var isSelected : Bool
        #if true // oh man, no proper equal in Swift :-) BAD BAD BAD
          if byVal {
            if let s = sel { // so bad, so wrong
              isSelected = UObject.isEqual(vs, s)
            }
            else {
              isSelected = false // wrong, selection could be nil and match
            }
          }
          else { // OMG
            isSelected = UObject.isEqual(sel, object)
          }
        #else
          if sel == (byVal ? v : object) { // Note: also matches null==null
            isSelected = true
          }
          else if sel == nil || (byVal ? v : object) == nil {
            isSelected = false
          }
          else {
            isSelected = sel == (byVal ? v : object)
          }
        #endif
        
        /* display string */
  
        let displayV : String? = {
          if let string = string {
            if let formatter = formatter {
              return formatter.string(for: string.value(in: cursor),
                                      in: context)
            }
            else {
              return string.stringValue(in: cursor)
            }
          }
          else {
            if let formatter = formatter {
              return formatter.string(for: object, in: context)
            }
            else {
              return UObject.stringValue(object)
            }
          }
        }()
  
        /* grouping */
  
        if let group = itemGroup?.stringValue(in: cursor) {
          var groupChanged = false
  
          if previousGroup == nil {
            groupChanged = true
          }
          else if group != previousGroup {
            try response.appendEndTag("optgroup")
            groupChanged = true
          }
          
          if groupChanged {
            try response.appendBeginTag("optgroup")
            try response.appendContentString(" label=\"")
            if escapesHTML { try response.appendContentHTMLString(group) }
            else           { try response.appendContentString    (group) }
            try response.appendContentCharacter("\"")
            try response.appendBeginTagEnd()
  
            previousGroup = group
          }
        }
        else if previousGroup != nil {
          try response.appendEndTag("optgroup")
          previousGroup = nil
        }
  
        /* option tag */
  
        try response.appendBeginTag("option");
        try response.appendAttribute("value", vs);
        if isSelected {
          foundSelection = true
          try response.appendAttribute("selected",
                         context.generateEmptyAttributes ? nil : "selected")
        }
        try response.appendBeginTagEnd();
  
        if let v = displayV {
          if escapesHTML { try response.appendContentHTMLString(v) }
          else           { try response.appendContentString    (v) }
        }
        
        try response.appendEndTag("option")
        
        i += 1
      }
    }

    /* close optgroups */
    
    if previousGroup != nil {
      try response.appendEndTag("optgroup")
    }
    
    /* process selections which where missing in the list */
    
    if let sel = sel, !foundSelection {
      // TBD
      let vs     : String?
      let object : Any?
  
      if byVal {
        /* Note: 'selection' might be available! (comparison by value has a
         * higher priority.
         */
        if hasSettableItem {
          if let selection = selection {
            object = selection.value(in: cursor)
            try item?.setValue(object, in: cursor)
          }
          else { object = nil }
        }
        else { object = nil }

        /* the value is what we detected */
        vs = UObject.stringValue(sel)
      }
      else {
        /* This means the 'selection' binding was set, but not the
         * 'selectedValue' one. 'sel' will point to the item.
         */
        object = sel
        if hasSettableItem { try item?.setValue(object, in: cursor) }
  
        /* determine value (DUP above) */
  
        let v : Any?
        if let readValue = readValue {
          v  = readValue.value(in: cursor)
          if let v = v { vs = UObject.stringValue(v) }
          else         { vs = nil }
        }
        else {
          vs = String(toGo) /* repetition index as the value! */
          v  = vs
        }
      }
  
      /* display string */
  
      let displayV : String?
      if let string = string {
        displayV = string.stringValue(in: cursor)
      }
      else if let object = object {
        displayV = UObject.stringValue(object)
      }
      else if let vs = vs { /* just the value */
        displayV = vs
      }
      else {
        displayV = "<null>" /* <> will get escaped below */
      }

      /* option tag */
  
      try response.appendBeginTag("option")
      try response.appendAttribute("value", vs)
      try response.appendAttribute("selected",
                     context.generateEmptyAttributes ? nil : "selected")
      try response.appendBeginTagEnd()
  
      if let v = displayV {
        if escapesHTML { try response.appendContentHTMLString(v) }
        else           { try response.appendContentString    (v) }
      }
  
      try response.appendEndTag("option")
    }
    
    /* reset item */
    if hasSettableItem {
      try? item?.setValue(nil /* reset */, in: cursor)
    }
  }

  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "list",              list,
      "item",              item,
      "selection",         selection,
      "string",            string,
      "noSelectionString", noSelectionString,
      "selectedValue",     selectedValue,
      "escapeHTML",        escapeHTML,
      "itemGroup",         itemGroup
    )
  }
}
