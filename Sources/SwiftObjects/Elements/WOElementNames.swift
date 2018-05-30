//
//  WOElementNames.swift
//  SwiftObjects
//
//  Created by Helge Hess on 20.05.18.
//

let WOElementNames : [ String : WODynamicElement.Type ] = {
  var map = [ String : WODynamicElement.Type ]()
  map.reserveCapacity(64)
  map.merge(WOBasicElementNames, uniquingKeysWith: { first, _ in first })
  map.merge(WOFormElementNames,  uniquingKeysWith: { first, _ in first })
  map.merge(WOMiscElementNames,  uniquingKeysWith: { first, _ in first })
  return map
}()

let WOBasicElementNames : [ String : WODynamicElement.Type ] = [
  "WOConditional"      : WOConditional.self,
  "WOGenericElement"   : WOGenericElement.self,
  "WOGenericContainer" : WOGenericContainer.self,
  "WOHyperlink"        : WOHyperlink.self,
  "WOImage"            : WOImage.self,
  "WORepetition"       : WORepetition.self,
  "WOString"           : WOString.self,
  "WOComponentContent" : WOComponentContent.self,
  "WOFragment"         : WOFragment.self
]

let WOFormElementNames : [ String : WODynamicElement.Type ] = [
  "WOCheckBox"         : WOCheckBox.self,
  "WOForm"             : WOForm.self,
  "WOHiddenField"      : WOHiddenField.self,
  "WOInput"            : WOInput.self,
  "WOResetButton"      : WOResetButton.self,
  "WOSearchField"      : WOSearchField.self,
  "WOSubmitButton"     : WOSubmitButton.self,
  "WOText"             : WOText.self,
  "WOTextField"        : WOTextField.self
]

let WOMiscElementNames : [ String : WODynamicElement.Type ] = [
  "WOConditionalComment" : WOConditionalComment.self,
  "WOEntity"             : WOEntity.self,
  "WOJavaScript"         : WOJavaScript.self,
  "WOParam"              : WOParam.self,
  "WOResourceURL"        : WOResourceURL.self,
  "WOSetHeader"          : WOSetHeader.self,
  "WOStylesheet"         : WOStylesheet.self,
  "WOXmlPreamble"        : WOXmlPreamble.self
]
