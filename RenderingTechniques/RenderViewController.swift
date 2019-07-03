//
//  RasterizationViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/8/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

class RenderViewController<RendererType: Renderer>: UIViewController {
    var renderOutputView: UIImageView!
    var fpsLabel: UILabel!
    var timer: CADisplayLink!
    var renderer: RendererType!

    override func viewDidLoad() {
        renderer = RendererType()

        renderOutputView = UIImageView()
        view.addSubview(renderOutputView)
        renderOutputView.translatesAutoresizingMaskIntoConstraints = false
        renderOutputView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        renderOutputView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        renderOutputView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        renderOutputView.heightAnchor.constraint(equalTo: renderOutputView.widthAnchor).isActive = true
        renderOutputView.backgroundColor = UIColor.gray

        fpsLabel = UILabel()
        fpsLabel.textColor = UIColor.white
        fpsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fpsLabel)
        fpsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        fpsLabel.topAnchor.constraint(equalTo: renderOutputView.bottomAnchor).isActive = true
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
        let width = Int(renderOutputView.frame.width)
        let height = Int(renderOutputView.frame.height)
        if let image = renderer.render(width: width, height: height) {
            renderOutputView.image = UIImage(cgImage: image)
            fpsLabel.text = String(format: "%.1 FPS", 1.0 / Float(-startTime.timeIntervalSinceNow))
        }
    }
}
