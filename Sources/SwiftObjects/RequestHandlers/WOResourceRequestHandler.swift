//
//  WOResourceRequestHandler.swift
//  SwiftObjects
//
//  Created by Helge Hess on 21.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import struct Foundation.URL

/**
 * This class is used for delivering static resource files, like images or
 * stylesheet. Usually you would want to deliver resource files using Apache
 * or some other frontend Apache server.
 */
open class WOResourceRequestHandler : WORequestHandler {
  
  open var application : WOApplication
  
  let log : WOLogger
  
  public init(application: WOApplication) {
    self.application = application
    self.log         = application.log
  }
  
  open func handleRequest(_ request: WORequest, in context: WOContext,
                          session: WOSession?) throws -> WOResponse?
  {
    let isFavIcon = request.uri == "/favicon.ico"
    
    let handlerPath = request.requestHandlerPathArray
    if !isFavIcon && handlerPath.isEmpty {
      log.error("URL resource path too short/missing.", request.uri)
      return nil
    }
    
    var languages = context.languages
    let resourceName : String
    
    if isFavIcon {
      resourceName = "favicon.ico"
    }
    else if handlerPath.count > 1 {
      resourceName = handlerPath[1]
      languages.insert(handlerPath[0], at: 0)
    }
    else {
      resourceName = handlerPath[0]
    }
    
    guard let rm = context.application.resourceManager else {
      log.error("missing resource manager!", self)
      return nil
    }
    
    guard let data = rm.dataForResourceNamed(resourceName,
                                             languages: languages) else {
      context.response.status = 404
      return context.response
    }
    
    let mimeType = WOResourceRequestHandler.mimeType(for: resourceName)
                ?? "application/octet-stream"
    
    let response = context.response
    response.setHeader(mimeType, for: "Content-Type")
    
    // TODO: Date, Expires
    
    if data.count > 10 {
      // GZip: 1F 8B - hack :-)
      if data[0] == 0x1F, data[1] == 0x8B {
        response.setHeader("gzip", for: "Content-Encoding")
      }
    }

    response.contents = data
    return response
  }
  
  public static func mimeType(for path: String) -> String? {
    return WOExtensionToMimeType[URL(fileURLWithPath: path).pathExtension]
  }
}

public let WOExtensionToMimeType : [ String : String ] = [
  "css"  : "text/css",
  "txt"  : "text/plain",
  "js"   : "text/javascript",
  "gif"  : "image/gif",
  "png"  : "image/png",
  "jpeg" : "image/jpeg",
  "jpg"  : "image/jpeg",
  "html" : "text/html",
  "xml"  : "text/xml",
  "ico"  : "image/x-icon"
]
