//
//  WOTagAliases.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//

import Foundation

// A map which maps short tag names like `<wo:for>` to their full name,
// like `WORepetition`. Also: HTML tags to `WOGenericElement`/`Container`.
let WOTagAliases : [ String : String ] = [
  "a"          : "WOHyperlink",
  "if"         : "WOConditional",
  "for"        : "WORepetition",
  "table-for"  : "WOTableRepetition",
  "get"        : "WOString",
  "put"        : "WOCopyValue",
  "submit"     : "WOSubmitButton",
  "form-value" : "WOFormValue",

  /* list of HTML tags (which can be made dynamic with a # in front */
  "html"       : "WOGenericContainer",
  "head"       : "WOGenericContainer",
  "body"       : "WOGenericContainer",
  "title"      : "WOGenericContainer",
  "link"       : "WOGenericElement",
  "base"       : "WOGenericElement",
  "meta"       : "WOGenericElement",
  "img"        : "WOGenericElement",
  "ul"         : "WOGenericContainer",
  "ol"         : "WOGenericContainer",
  "li"         : "WOGenericContainer",
  "table"      : "WOGenericContainer",
  "tr"         : "WOGenericContainer",
  "th"         : "WOGenericContainer",
  "td"         : "WOGenericContainer",
  "label"      : "WOGenericContainer",
  "br"         : "WOGenericElement",
  "hr"         : "WOGenericElement",
  "input"      : "WOGenericElement",
  "select"     : "WOGenericContainer",
  "option"     : "WOGenericContainer",
  "form"       : "WOGenericContainer",
  "textarea"   : "WOGenericContainer",
  "font"       : "WOGenericContainer",
  "p"          : "WOGenericContainer",
  "div"        : "WOGenericContainer",
  "span"       : "WOGenericContainer",
  "iframe"     : "WOGenericContainer",
  "frame"      : "WOGenericContainer",
  "frameset"   : "WOGenericContainer",
  "script"     : "WOGenericContainer",
  "applet"     : "WOGenericContainer",
  "param"      : "WOGenericElement",
  "blink"      : "WOGenericContainer", /* ;-) */

  /* WML stuff */
  "wml"        : "WOGenericContainer",
  "card"       : "WOGenericContainer",
  "do"         : "WOGenericContainer",
  "go"         : "WOGenericContainer",
  "anchor"     : "WOGenericContainer",
  "postfield"  : "WOGenericContainer"
]
