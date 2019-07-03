//
//  RaycasterViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/21/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

final class RaycasterRenderer: Renderer {

    var stoneWallTextureData: UIImage = UIImage(named: "greystone.png")!
    var redBrickTextureData: UIImage = UIImage(named: "redbrick.png")!

    let textureWidth: Int = 64
    let textureHeight: Int = 64

    let cameraPosition: Vector2D = Vector2D(x: 3.5, y: 3.5)
    var cameraRotation: Float = 0.0

    let worldMap: [[Int]] =
       [[1, 1, 2, 2, 2, 1, 1],
        [1, 0, 2, 0, 2, 1, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [2, 2, 0, 0, 0, 2, 2],
        [2, 2, 1, 1, 1, 2, 2]]

    var height: Int = 0
    var width: Int = 0
    var output: [[Color]] = [[Color]]()

    func render(width: Int, height: Int) -> CGImage? {
        self.height = height
        self.width = width

        clearOutput()

        cameraRotation += 0.01

        for xPos in 0..<width {
            drawColumn(column: xPos)
        }
        return CGImage.image(colorData: output)
    }

    func clearOutput() {
        output = [[Color]](repeating: [Color](repeating: Color.gray, count: height), count: width)
    }

    func makeRayThatIntersectsColumn(column: Int) -> Vector2D {
        let viewDirection = Vector2D(x: -1.0, y: 0.0).rotate(angle: cameraRotation)
        let plane = Vector2D(x: 0.0, y: 0.5).rotate(angle: cameraRotation)

        let cameraX = 2.0 * Float(column) / Float(width) - 1.0
        return Vector2D(x: viewDirection.x + plane.x * cameraX, y: viewDirection.y + plane.y * cameraX)

    }

    func drawColumn(column: Int) {
        // Generate the ray that represents our current view
        let ray = makeRayThatIntersectsColumn(column: column)

        // The starting map coordinate
        var mapCoordinateX = Int(cameraPosition.x)
        var mapCoordinateY = Int(cameraPosition.y)

        //The direction we step through the map.
        let wallStepX = (ray.x < 0) ? -1 : 1
        let wallStepY = (ray.y < 0) ? -1 : 1

        //The length of the ray from one x-side to next x-side and y-side to next y-side
        let deltaDistanceX = ray.x == 0 ? Float.greatestFiniteMagnitude : sqrt(1.0 + (ray.y * ray.y) / (ray.x * ray.x))
        let deltaDistanceY = ray.y == 0 ? Float.greatestFiniteMagnitude : sqrt(1.0 + (ray.x * ray.x) / (ray.y * ray.y))

        //Length of ray from player to next x-side or y-side
        var sideDistanceX = (ray.x < 0) ? (cameraPosition.x - Float(mapCoordinateX)) * deltaDistanceX : (Float(mapCoordinateX) + 1.0 - cameraPosition.x) * deltaDistanceX
        var sideDistanceY = (ray.y < 0) ? (cameraPosition.y - Float(mapCoordinateY)) * deltaDistanceY : (Float(mapCoordinateY) + 1.0 - cameraPosition.y) * deltaDistanceY

        // Let's track if we hit the x-side or y-side?
        var isSideHit = false

        // Find the next wall intersection by checking the x and y sides along the direction of the ray.
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

        //We've hit a wall. Get the wall distance
        var wallDistance: Float = 0.0
        if isSideHit == false {
            wallDistance = (Float(mapCoordinateX) - cameraPosition.x + (1.0 - Float(wallStepX)) / 2.0) / ray.x
        } else {
            wallDistance = (Float(mapCoordinateY) - cameraPosition.y + (1.0 - Float(wallStepY)) / 2.0) / ray.y
        }

        //Get the beginning and ending y pixel values to draw
        let lineHeight = Int(Float(height) / wallDistance)
        let yStartPixel = -lineHeight / 2 + height / 2
        let yEndPixel = lineHeight / 2 + height / 2

        //G et the texture data for thw all
        let texture = worldMap[mapCoordinateX][mapCoordinateY] == 1 ? stoneWallTextureData : redBrickTextureData

        // Calculate the x point on the wall that was hit
        var wallHitPositionX: Float = 0.0
        if isSideHit == false {
            wallHitPositionX = cameraPosition.y + wallDistance * ray.y
        } else {
            wallHitPositionX = cameraPosition.x + wallDistance * ray.x
        }

        wallHitPositionX -= floor((wallHitPositionX))

        // Go through and draw each pixel in the column
        let wallHitPositionStartY: Float = Float(height) / 2.0 - Float(lineHeight) / 2.0
        for yPixel in yStartPixel..<yEndPixel {
            let wallHitPositionY: Float = (Float(yPixel) - wallHitPositionStartY) / Float(lineHeight)
            let color = texture.getPixelColor(pixelX: Int(wallHitPositionX * Float(textureWidth)), pixelY: Int(wallHitPositionY * Float(textureHeight)))
            output[yPixel][column] = color * (isSideHit ? 0.5 : 1.0)
        }
    }
}

extension UIImage {

    func getPixelColor(pixelX: Int, pixelY: Int) -> Color {

        if let pixelData = self.cgImage?.dataProvider?.data {
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

            let pixelInfo = (Int(self.size.width) * pixelY + pixelX) * 4

            let red = Float(data[pixelInfo+0]) / 255.0
            let green = Float(data[pixelInfo+1]) / 255.0
            let blue = Float(data[pixelInfo+2]) / 255.0

            return Color(red: red, green: green, blue: blue)
        } else {
            return Color.black
        }
    }
}
