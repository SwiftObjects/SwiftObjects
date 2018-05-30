// swift-tools-version:4.0
//
//  Package.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//
import PackageDescription

#if swift(>=4.1)
    let runtimeLib : PackageDescription.Package.Dependency =
                     .package(url: "https://github.com/wickwirew/Runtime.git",
                              from: "0.7.1")
#else
    let runtimeLib : PackageDescription.Package.Dependency =
                     .package(url: "https://github.com/wickwirew/Runtime.git",
                              .branch("swift-4"))
#endif

let package = Package(
    name: "SwiftObjects",
    
    products: [
      .library(name: "SwiftObjects", targets: [ "SwiftObjects"  ]),
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git",
                 from: "1.7.0"),
        .package(url: "https://github.com/onmyway133/SwiftHash.git",
                 from: "2.0.1"),
        runtimeLib,
        
        // just for the showcase
        .package(url: "https://github.com/SwiftWebResources/SemanticUI-Swift.git",
                 from: "2.3.1"),
        .package(url: "https://github.com/SwiftWebResources/jQuery-Swift.git",
                 from: "3.3.1"),
    ],

    targets: [
        .target(name: "SwiftObjects", 
                dependencies: [
                    "NIO",
                    "NIOHTTP1",
                    "NIOFoundationCompat",
                    "NIOConcurrencyHelpers",
                    "SwiftHash",
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
