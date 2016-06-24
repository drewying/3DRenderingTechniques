//
//  RenderView.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/11/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit


struct Color8 {
    let a:UInt8;
    let r:UInt8;
    let g:UInt8;
    let b:UInt8;
}

class RenderView: UIView {
    
    var width:Int = 0
    var height:Int = 0
    
    
    var pixelBuffer:[Color8] = [Color8]()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.width = Int(bounds.size.width)
        self.height = Int(bounds.size.height)
    }
    
    func clear(){
        pixelBuffer = Array<Color8>(count: width * height, repeatedValue: Color8(a: 255, r: 85, g: 85, b: 85))
    }
    
    func plot(x:Int, y:Int, color:Color8){
        if (x < 0 || y < 0 || x >= width || y >= height){
            return;
        }
        pixelBuffer[y * width + x] = color;
    }
    
    func render(){
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        
        var data = pixelBuffer // Copy to mutable []
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: &data, length: data.count * sizeof(Color8))
        )
        
        layer.contents = CGImageCreate(
            width,
            height,
            bitsPerComponent,
            bitsPerPixel,
            width * Int(sizeof(Color8)),
            rgbColorSpace,
            bitmapInfo,
            providerRef,
            nil,
            true,
            .RenderingIntentDefault
        )
    }

}

func * (left: Color8, right: Float) -> Color8{
    let r:Float = max(min(Float(left.r) * clamp(right), 255.0), 0.0)
    let g:Float = max(min(Float(left.g) * clamp(right), 255.0), 0.0)
    let b:Float = max(min(Float(left.b) * clamp(right), 255.0), 0.0)
    return Color8(a: 255, r: UInt8(r), g: UInt8(g), b: UInt8(b))
}

func + (left: Color8, right: Color8) -> Color8{
    let r:Float = max(min(Float(left.r) + Float(right.r), 255.0), 0.0)
    let g:Float = max(min(Float(left.g) + Float(right.g), 255.0), 0.0)
    let b:Float = max(min(Float(left.b) + Float(right.b), 255.0), 0.0)
    
    return Color8(a: 255, r: UInt8(r), g: UInt8(g), b: UInt8(b))
}
