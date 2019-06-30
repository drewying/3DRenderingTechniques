//
//  RasterizationViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/8/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

class RenderViewController<RendererType: Renderer>: UIViewController {
    var renderOutputView: UIView!
    var fpsLabel: UILabel!
    var timer: CADisplayLink!
    var renderer: RendererType!

    override func viewDidLoad() {
        renderer = RendererType()

        renderOutputView = UIView()
        view.addSubview(renderOutputView)
        renderOutputView.translatesAutoresizingMaskIntoConstraints = false
        renderOutputView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        renderOutputView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        renderOutputView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        renderOutputView.heightAnchor.constraint(equalTo: renderOutputView.widthAnchor).isActive = true
        renderOutputView.backgroundColor = UIColor.gray

        fpsLabel = UILabel()
        fpsLabel.textColor = UIColor.white
        fpsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fpsLabel)
        fpsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        fpsLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer = CADisplayLink(target: self, selector: #selector(renderLoop))
        timer.add(to: .current, forMode: .common)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }

    @objc func renderLoop() {
        let startTime: NSDate = NSDate()
        let output = renderer.render(width: Int(renderOutputView.frame.width), height: Int(renderOutputView.frame.height))

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32

        var pixelData = [UInt8]()
        for colorArray in output {
            for color in colorArray {
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0

                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                pixelData.append(UInt8(alpha * 255))
                pixelData.append(UInt8(red * 255))
                pixelData.append(UInt8(green * 255))
                pixelData.append(UInt8(blue * 255))
            }
        }

        guard let providerRef = CGDataProvider(data: NSData(bytes: &pixelData, length: pixelData.count)) else {
            return
        }

        renderOutputView.layer.contents = CGImage(
            width: Int(renderOutputView.frame.width),
            height: Int(renderOutputView.frame.height),
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: Int(renderOutputView.frame.width) * 4,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )

        fpsLabel.text = String(format: "%.1 FPS", 1.0 / Float(-startTime.timeIntervalSinceNow))
    }
}
