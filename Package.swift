// swift-tools-version:4.2
//
//  Package.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//
import PackageDescription

#if swift(>=4.1.50)
  #if compiler(>=5.0)
    let runtimeLib: PackageDescription.Package.Dependency =
                    .package(url: "https://github.com/wickwirew/Runtime.git",
                             .branch("swift5"))
  #else // 4.2
    let runtimeLib: PackageDescription.Package.Dependency =
                    .package(url: "https://github.com/wickwirew/Runtime.git",
                             from: "1.1.0")
  #endif
#elseif swift(>=4.1)
    let runtimeLib: PackageDescription.Package.Dependency =
                    .package(url: "https://github.com/SwiftObjects/Runtime.git",
                             from: "41.0.0")
#else // ooold
    let runtimeLib: PackageDescription.Package.Dependency =
                    .package(url: "https://github.com/SwiftObjects/Runtime.git",
                             from: "40.0.0")
#endif

let package = Package(
    name: "SwiftObjects",
    
    products: [
      .library(name: "SwiftObjects", targets: [ "SwiftObjects"  ]),
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git",
                 from: "1.13.2"),
        .package(url: "https://github.com/onmyway133/SwiftHash.git",
                 from: "2.0.2"),
        runtimeLib,
        
        // just for the showcase
        .package(url: "https://github.com/SwiftWebResources/SemanticUI-Swift.git",
                 from: "2.3.3"),
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
