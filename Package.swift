// swift-tools-version:5.0
//
//  Package.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2020 ZeeZide. All rights reserved.
//
import PackageDescription

let package = Package(
    name: "SwiftObjects",
    
    products: [
      .library(name: "SwiftObjects", targets: [ "SwiftObjects"  ]),
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git",
                 from: "2.25.1"),
        .package(url: "https://github.com/wickwirew/Runtime.git",
                 from: "2.2.2"),
        
        // just for the showcase
        .package(url: "https://github.com/SwiftWebResources/SemanticUI-Swift.git",
                 from: "2.4.2"),
        .package(url: "https://github.com/SwiftWebResources/jQuery-Swift.git",
                 from: "3.5.1"),
    ],

    targets: [
        .target(name: "SwiftObjects", 
                dependencies: [
                    "NIO",
                    "NIOHTTP1",
                    "NIOFoundationCompat",
                    "NIOConcurrencyHelpers",
                    "Runtime"
                ]),
        .testTarget(name: "SwiftObjectsTests",
                    dependencies: [ "SwiftObjects" ]),

        .target(name: "WOShowcaseApp",
                dependencies: [
                  "SwiftObjects",
                  "SemanticUI",
                  "jQuery"
                ]),
    ]
)
