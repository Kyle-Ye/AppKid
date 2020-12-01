// swift-tools-version:5.3
//
//  Package.swift
//  AppKid
//
//  Created by Serhii Mumriak on 11.05.2020.
//

import PackageDescription

let package = Package(
    name: "AppKid",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "AppKid", type: .dynamic, targets: ["AppKid"]),
    ],
    dependencies: [
        .package(path: "../SharedSystemLibs"),
        .package(path: "../TinyFoundation"),
        .package(path: "../CairoGraphics"),
        .package(path: "../ContentAnimation"),
        .package(path: "../Volcano"),
        .package(name: "cglm", url: "https://github.com/recp/cglm", .branch("master")),
        .package(path: "../SimpleGLM"),
    ],
    targets: [
        .target(
            name: "AppKid",
            dependencies: [
                .product(name: "CXlib", package: "SharedSystemLibs"),
                .product(name: "CXInput2", package: "SharedSystemLibs"),
                .product(name: "CVulkan", package: "SharedSystemLibs"),
                .product(name: "CairoGraphics", package: "CairoGraphics"),
                .product(name: "ContentAnimation", package: "ContentAnimation"),
                .product(name: "TinyFoundation", package: "TinyFoundation"),
                .product(name: "Volcano", package: "Volcano"),
                .product(name: "cglm", package: "cglm"),
                .product(name: "SimpleGLM", package: "SimpleGLM"),
            ],
            exclude: [
                "Resources/TriangleFragmentShader.frag",
                "Resources/TriangleVertexShader.vert",
                "Resources/VertexShader.vert",
            ],
            resources: [
                .copy("Resources/TriangleFragmentShader.spv"),
                .copy("Resources/TriangleVertexShader.spv"),
                .copy("Resources/VertexShader.spv"),
            ]
        ),
    ]
)
