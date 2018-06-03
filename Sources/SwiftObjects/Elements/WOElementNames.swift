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
  map.merge(WOLinkElementNames,  uniquingKeysWith: { first, _ in first })
  map.merge(WOMiscElementNames,  uniquingKeysWith: { first, _ in first })
  return map
}()

let WOBasicElementNames  : [ String : WODynamicElement.Type ] = [
  "WOComponentContent"   : WOComponentContent.self,
  "WOConditional"        : WOConditional.self,
  "WOFragment"           : WOFragment.self,
  "WOGenericContainer"   : WOGenericContainer.self,
  "WOGenericElement"     : WOGenericElement.self,
  "WOHyperlink"          : WOHyperlink.self,
  "WOImage"              : WOImage.self,
  "WORepetition"         : WORepetition.self,
  "WOString"             : WOString.self,
  "WOSwitchComponent"    : WOSwitchComponent.self,
]

let WOFormElementNames   : [ String : WODynamicElement.Type ] = [
  "WOCheckBox"           : WOCheckBox.self,
  "WOForm"               : WOForm.self,
  "WOHiddenField"        : WOHiddenField.self,
  "WOInput"              : WOInput.self,
  "WOResetButton"        : WOResetButton.self,
  "WOSearchField"        : WOSearchField.self,
  "WOSubmitButton"       : WOSubmitButton.self,
  "WOText"               : WOText.self,
  "WOTextField"          : WOTextField.self,
  "WOPopUpButton"        : WOPopUpButton.self,
  "WORadioButton"        : WORadioButton.self,
  "WOPasswordField"      : WOPasswordField.self,
  "WOBrowser"            : WOBrowser.self,
]

let WOLinkElementNames   : [ String : WODynamicElement.Type ] = [
  "WOActionURL"          : WOActionURL.self,
  "WOResourceURL"        : WOResourceURL.self,
]

let WOMiscElementNames   : [ String : WODynamicElement.Type ] = [
  "WOConditionalComment" : WOConditionalComment.self,
  "WOEntity"             : WOEntity.self,
  "WOJavaScript"         : WOJavaScript.self,
  "WOParam"              : WOParam.self,
  "WOSetHeader"          : WOSetHeader.self,
  "WOStylesheet"         : WOStylesheet.self,
  "WOXmlPreamble"        : WOXmlPreamble.self,
  "WOBody"               : WOBody.self,
  "WOFrame"              : WOFrame.self,
  "WOIFrame"             : WOIFrame.self,
  "WOHtml"               : WOHtml.self,
]

let WOFormatterNames     : [ String : WOFormatter.Type ] = [
  "WODateFormatter"      : WODateFormatter.self,
  "WONumberFormatter"    : WONumberFormatter.self,
  "WOObjectFormatter"    : WOObjectFormatter.self,
]
