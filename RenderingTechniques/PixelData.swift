//
//  PixelData.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/8/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct PixelColor {
    var a:UInt8;
    var r:UInt8;
    var g:UInt8;
    var b:UInt8;
}

class PixelData: NSObject {
    
    let width:Int;
    let height:Int;
    var pixelBuffer:[PixelColor];
    
    init(width:Int, height:Int) {
        self.width = width;
        self.height = height;
        pixelBuffer = Array<PixelColor>(count: width * height, repeatedValue: PixelColor(a: 255, r: 0, g: 0, b: 0))
    }
    
    func plot(x:Int, y:Int, pixelColor:PixelColor){
        if (x < 0 || y < 0 || x >= width || y >= height){
            return;
        }
        pixelBuffer[y * width + x] = pixelColor;
    }
    
    func clear() {
        pixelBuffer = Array<PixelColor>(count: width * height, repeatedValue: PixelColor(a: 255, r: 0, g: 0, b: 0))
    }
    
    func getImageRepresentation() -> UIImage {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        
        var data = pixelBuffer // Copy to mutable []
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: &data, length: data.count * sizeof(PixelColor))
        )
        
        let cgim = CGImageCreate(
            width,
            height,
            bitsPerComponent,
            bitsPerPixel,
            width * Int(sizeof(PixelColor)),
            rgbColorSpace,
            bitmapInfo,
            providerRef,
            nil,
            true,
            .RenderingIntentDefault
        )
        return UIImage(CGImage: cgim!)
    }
}
