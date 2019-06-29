//
//  RenderView.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/11/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

// swiftlint:disable variable_name
struct Color {
    let r: Float
    let g: Float
    let b: Float
}

struct Color8 {
    let a: UInt8
    let r: UInt8
    let g: UInt8
    let b: UInt8
}

func * (left: Color, right: Float) -> Color {
    return Color(r: left.r * right, g: left.g * right, b: left.b * right)
}

func * (left: Color, right: Color) -> Color {
    return Color(r: left.r * right.r, g: left.g * right.g, b: left.b * right.b)
}

func + (left: Color, right: Color) -> Color {
    return Color(r: left.r + right.r, g: left.g + right.g, b: left.b + right.b)
}

class RenderView: UIView {

    var width: Int = 0
    var height: Int = 0

    var pixelBuffer: [Color8] = [Color8]()

    override func layoutSubviews() {
        super.layoutSubviews()
        self.width = Int(bounds.size.width)
        self.height = Int(bounds.size.height)
    }

    func clear() {
        pixelBuffer = [Color8](repeating: Color8(a: 255, r: 85, g: 85, b: 85), count: width * height)
    }

    func plot(x: Int, y: Int, color: Color) {
        if x < 0 || y < 0 || x >= width || y >= height {
            return
        }
        let red: UInt8 = UInt8(clamp(color.r) * 255)
        let green: UInt8 = UInt8(clamp(color.g) * 255)
        let blue: UInt8 = UInt8(clamp(color.b) * 255)

        pixelBuffer[y * width + x] = Color8(a: 255, r: red, g: green, b: blue)
    }

    func render() {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32

        var data = pixelBuffer // Copy to mutable []
        guard let providerRef = CGDataProvider(data: NSData(bytes: &data, length: data.count * 4)) else {
            return
        }

        layer.contents = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * 4,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
// swiftlint:enable variable_name
