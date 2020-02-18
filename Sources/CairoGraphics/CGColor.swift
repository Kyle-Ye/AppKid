//
//  CGColor.swift
//  CairoGraphics
//
//  Created by Serhii Mumriak on 9/2/20.
//

import Foundation

// palkovnik:TODO: placeholder because color spaces are hard
public struct CGColor {
    public var red: CGFloat = .zero
    public var green: CGFloat = .zero
    public var blue: CGFloat = .zero
    public var alpha: CGFloat = 1.0
}

public extension CGColor {
    static let clear = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    
    static let red = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    static let green = CGColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
    static let blue = CGColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
    
    static let black = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    static let white = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    static let gray = CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
}

extension CGColor: Equatable {
    public static func == (lhs: CGColor, rhs: CGColor) -> Bool {
        return lhs.red == rhs.red &&
            lhs.green == rhs.green &&
            lhs.blue == rhs.blue &&
            lhs.alpha == rhs.alpha
    }
}

public extension CGColor {
    var negative: CGColor {
        return CGColor(red: alpha - red, green: alpha - green, blue: alpha - blue, alpha: alpha)
    }
}
