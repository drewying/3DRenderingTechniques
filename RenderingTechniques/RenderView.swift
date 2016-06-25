//
//  RenderView.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/11/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit


struct Color {
    let r:Float
    let g:Float
    let b:Float
}

func * (left: Color, right: Float) -> Color{
    return Color(r: left.r * right, g: left.g * right, b: left.b * right)
}

func * (left: Color, right: Color) -> Color{
    return Color(r: left.r * right.r, g: left.g * right.g, b: left.b * right.b)
}

func + (left: Color, right: Color) -> Color{
    return Color(r: left.r + right.r, g: left.g + right.g, b: left.b + right.b)
}

class RenderView: UIView {
    

    var width:Int = 0
    var height:Int = 0
    
    
    var pixelBuffer:[(UInt8, UInt8, UInt8, UInt8)] = [(UInt8, UInt8, UInt8, UInt8)]()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.width = Int(bounds.size.width)
        self.height = Int(bounds.size.height)
    }
    
    func clear(){
        pixelBuffer = Array<(UInt8, UInt8, UInt8, UInt8)>(count: width * height, repeatedValue: (255, 85, 85, 85))
    }
    
    func plot(x:Int, y:Int, color:Color){
        if (x < 0 || y < 0 || x >= width || y >= height){
            return;
        }
        let r:UInt8 = UInt8(clamp(color.r) * 255)
        let g:UInt8 = UInt8(clamp(color.g) * 255)
        let b:UInt8 = UInt8(clamp(color.b) * 255)
        
        pixelBuffer[y * width + x] = (255, r, g, b)
    }
    
    func render(){
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        
        var data = pixelBuffer // Copy to mutable []
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: &data, length: data.count * sizeof(UInt8) * 4)
        )
        
        layer.contents = CGImageCreate(
            width,
            height,
            bitsPerComponent,
            bitsPerPixel,
            width * Int(sizeof(UInt8)) * 4,
            rgbColorSpace,
            bitmapInfo,
            providerRef,
            nil,
            true,
            .RenderingIntentDefault
        )
    }

}


