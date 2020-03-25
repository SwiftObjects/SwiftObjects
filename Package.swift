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
                 from: "2.15.0"),
        .package(url: "https://github.com/SwiftObjects/Runtime.git",
                 from: "50.0.0"),
        
        // just for the showcase
        .package(url: "https://github.com/SwiftWebResources/SemanticUI-Swift.git",
                 from: "2.3.4"),
        .package(url: "https://github.com/SwiftWebResources/jQuery-Swift.git",
                 from: "3.3.2"),
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
