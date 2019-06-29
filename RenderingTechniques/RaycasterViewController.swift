//
//  RaycasterViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/21/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

class RaycasterViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    @IBOutlet weak var fpsLabel: UILabel!
    var timer: CADisplayLink! = nil
    var currentRotation: Float = 0.0

    var stoneWallTextureData: UIImage = UIImage(named: "greystone.png")!
    var redBrickTextureData: UIImage = UIImage(named: "redbrick.png")!

    let textureWidth: Int = 64
    let textureHeight: Int = 64

    let playerPosition: Vector2D = Vector2D(x: 3.5, y: 3.5)
    let worldMap: [[Int]] =
       [[1, 1, 2, 2, 2, 1, 1],
        [1, 0, 2, 0, 2, 1, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [2, 2, 0, 0, 0, 2, 2],
        [2, 2, 1, 1, 1, 2, 2]]

    @objc func renderLoop() {
        let startTime: NSDate = NSDate()

        renderView.clear()

        for column: Int in 0 ..< renderView.width {
            drawColumn(column: column)
        }

        renderView.render()
        currentRotation += 0.01
        self.fpsLabel.text = String(format: "%.1 FPS", 1.0 / Float(-startTime.timeIntervalSinceNow))
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

    func drawColumn(column: Int) {
        let viewDirection = Vector2D(x: -1.0, y: 0.0).rotate(angle: currentRotation)
        let plane = Vector2D(x: 0.0, y: 0.5).rotate(angle: currentRotation)

        let cameraX = 2.0 * Float(column) / Float(renderView.width) - 1.0
        let rayDirection = Vector2D(x: viewDirection.x + plane.x * cameraX, y: viewDirection.y + plane.y * cameraX)

        //The starting map coordinate
        var mapCoordinateX = Int(playerPosition.x)
        var mapCoordinateY = Int(playerPosition.y)

        //The direction we step through the map.
        let wallStepX = (rayDirection.x < 0) ? -1 : 1
        let wallStepY = (rayDirection.y < 0) ? -1 : 1

        //The length of the ray from one x-side to next x-side and y-side to next y-side
        let deltaDistanceX = rayDirection.x == 0 ? Float.greatestFiniteMagnitude : sqrt(1.0 + (rayDirection.y * rayDirection.y) / (rayDirection.x * rayDirection.x))
        let deltaDistanceY = rayDirection.y == 0 ? Float.greatestFiniteMagnitude : sqrt(1.0 + (rayDirection.x * rayDirection.x) / (rayDirection.y * rayDirection.y))

        //Length of ray from player to next x-side or y-side
        var sideDistanceX = (rayDirection.x < 0) ? (playerPosition.x - Float(mapCoordinateX)) * deltaDistanceX : (Float(mapCoordinateX) + 1.0 - playerPosition.x) * deltaDistanceX
        var sideDistanceY = (rayDirection.y < 0) ? (playerPosition.y - Float(mapCoordinateY)) * deltaDistanceY : (Float(mapCoordinateY) + 1.0 - playerPosition.y) * deltaDistanceY

        //Did we hit the x-side or y-side?
        var isSideHit: Bool = false

        //Find the next wall intersection by checking the x and y sides along the direction of the ray.
        while worldMap[mapCoordinateX][mapCoordinateY] <= 0 {
            if sideDistanceX < sideDistanceY {
                sideDistanceX += deltaDistanceX
                mapCoordinateX += wallStepX
                isSideHit = false
            } else {
                sideDistanceY += deltaDistanceY
                mapCoordinateY += wallStepY
                isSideHit = true
            }
        }

        //We've hit a wal. Get the wall distance
        var wallDistance: Float = 0.0
        if isSideHit == false {
            wallDistance = (Float(mapCoordinateX) - playerPosition.x + (1.0 - Float(wallStepX)) / 2.0) / rayDirection.x
        } else {
            wallDistance = (Float(mapCoordinateY) - playerPosition.y + (1.0 - Float(wallStepY)) / 2.0) / rayDirection.y
        }

        //Get the beginning and ending y pixel values to draw
        let lineHeight: Int = Int(Float(renderView.height) / wallDistance)
        let yStartPixel = -lineHeight / 2 + renderView.height / 2
        let yEndPixel = lineHeight / 2 + renderView.height / 2

        //Get the texture data for thw all
        let texture = worldMap[mapCoordinateX][mapCoordinateY] == 1 ? stoneWallTextureData : redBrickTextureData

        //Calculate the x point on the wall that was hit
        var wallHitPositionX: Float = 0.0
        if isSideHit == false {
            wallHitPositionX = playerPosition.y + wallDistance * rayDirection.y
        } else {
            wallHitPositionX = playerPosition.x + wallDistance * rayDirection.x
        }

        wallHitPositionX -= floor((wallHitPositionX))

        //Go through and plot each pixel in the column
        let wallHitPositionStartY: Float = Float(renderView.height) / 2.0 - Float(lineHeight) / 2.0
        for yPixel in yStartPixel..<yEndPixel {
            let wallHitPositionY: Float = (Float(yPixel) - wallHitPositionStartY) / Float(lineHeight)
            let color = texture.getPixelColor(pixelX: Int(wallHitPositionX * Float(textureWidth)), pixelY: Int(wallHitPositionY * Float(textureHeight)))
            renderView.plot(x: column, y: yPixel, color: color * (isSideHit ? 0.5 : 1.0))
        }
    }
}

extension UIImage {

    func getPixelColor(pixelX: Int, pixelY: Int) -> Color {

        if let pixelData = self.cgImage?.dataProvider?.data {
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

            let pixelInfo: Int = (Int(self.size.width) * pixelY + pixelX) * 4

            let red = Float(data[pixelInfo+0]) / 255.0
            let green = Float(data[pixelInfo+1]) / 255.0
            let blue = Float(data[pixelInfo+2]) / 255.0

            return Color(r: red, g: green, b: blue)
        } else {
            return Color(r: 0, g: 0, b: 0)
        }
    }
}
