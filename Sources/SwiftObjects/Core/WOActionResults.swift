//
//  WOActionResults.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

public protocol WOActionResults {
  
  func generateResponse() throws -> WOResponse
  
}
