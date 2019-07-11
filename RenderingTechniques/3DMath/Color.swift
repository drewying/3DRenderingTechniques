//
//  Color.swift
//  RenderingTechniques
//
//  Created by Ingebretsen, Andrew (HBO) on 7/3/19.
//  Copyright © 2019 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct Color {
    let red: Float
    let green: Float
    let blue: Float
    var bitmapReprensetation: UInt32 {
        return UInt32(clamp(blue)  * 255) << 24 |
               UInt32(clamp(green) * 255) << 16 |
               UInt32(clamp(red)   * 255) <<  8 |
               0
    }

    static let black     = Color(red: 0, green: 0, blue: 0)
    static let white     = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let offWhite  = Color(red: 0.85, green: 0.85, blue: 0.85)
    static let gray      = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let royalBlue = Color(red: 0.25, green: 0.25, blue: 0.75)
    static let crimson   = Color(red: 0.75, green: 0.25, blue: 0.25)
    static let green     = Color(red: 0.25, green: 0.75, blue: 0.25)
}

extension CGImage {
    static func image(colorData: [[Color]]) -> CGImage? {
        var pixelData = colorData.joined().map { $0.bitmapReprensetation }

        guard let cgPixelData = CGDataProvider(data: NSData(bytes: &pixelData, length: pixelData.count * 4)) else {
            return nil
        }

        return CGImage(
            width: colorData.count,
            height: colorData[0].count,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: colorData.count * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue),
            provider: cgPixelData,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
func + (left: Color, right: Float) -> Color {
    return Color(red: left.red + right, green: left.green + right, blue: left.blue + right)
}

func * (left: Color, right: Float) -> Color {
    return Color(red: left.red * right, green: left.green * right, blue: left.blue * right)
}

func / (left: Color, right: Float) -> Color {
    return Color(red: left.red / right, green: left.green / right, blue: left.blue / right)
}

func * (left: Color, right: Color) -> Color {
    return Color(red: left.red * right.red, green: left.green * right.green, blue: left.blue * right.blue)
}

func + (left: Color, right: Color) -> Color {
    return Color(red: left.red + right.red, green: left.green + right.green, blue: left.blue + right.blue)
}
