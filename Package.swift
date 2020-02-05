// swift-tools-version:5.1
//
//  Package.swift
//  SwiftyFan
//
//  Created by Serhii Mumriak on 29/1/20.
//

import PackageDescription

let package = Package(
    name: "SwiftyFan",
    platforms: [
        .macOS(.v10_12)
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .systemLibrary(
            name: "CX11",
            pkgConfig: "x11",
            providers: [
                .apt(["libx11-dev"]),
                .brew(["xquartz"])
            ]
        ),
        .systemLibrary(name: "CEpoll"),
        .systemLibrary(
            name: "CCairo",
            pkgConfig: "cairo",
            providers: [
                .apt(["libcairo2-dev"]),
                .brew(["cairo"])
            ]
        ),
        .target(
            name: "SwiftyFan",
            dependencies: ["AppKid"]
        ),
        .target(
            name: "AppKid",
            dependencies: ["CX11", "CEpoll", "CairoGraphics"]
        ),
        .target(
            name: "CairoGraphics",
            dependencies: ["CCairo"]
        ),
        .testTarget(
            name: "SwiftyFanTests",
            dependencies: ["SwiftyFan"]
        ),
    ]
)
