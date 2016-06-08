//
//  PixelData.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/8/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct Pixel {
    var a:UInt8;
    var r:UInt8;
    var g:UInt8;
    var b:UInt8;
}

class PixelData: NSObject {
    
    let width:Int;
    let height:Int;
    var pixelBuffer:[Pixel];
    
    init(width:Int, height:Int) {
        self.width = width;
        self.height = height;
        pixelBuffer = Array<Pixel>(count: width * height, repeatedValue: Pixel(a: 255, r: 0, g: 0, b: 0))
    }
    
    func plot(x:Int, y:Int, red:UInt8, green:UInt8, blue:UInt8, alpha:UInt8){
        if (x < 0 || y < 0){
            return;
        }
        pixelBuffer[y * width + x] = Pixel(a: alpha, r: red, g: green, b: blue)
    }
    
    func getImageRepresentation() -> UIImage {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        
        var data = pixelBuffer // Copy to mutable []
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: &data, length: data.count * sizeof(Pixel))
        )
        
        let cgim = CGImageCreate(
            width,
            height,
            bitsPerComponent,
            bitsPerPixel,
            width * Int(sizeof(Pixel)),
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
