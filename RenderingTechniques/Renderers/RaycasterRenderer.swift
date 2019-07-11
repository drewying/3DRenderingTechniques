//
//  RaycasterViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/21/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

final class RaycasterRenderer: Renderer {

    lazy var stoneWallTexture: [[Color]] = {
        return loadTextureData(fileName: "greystone.png")
    }()

    lazy var brickWallTexture: [[Color]] = {
        return loadTextureData(fileName: "redbrick.png")
    }()

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
        // Generate a ray that passes through the specified column
        let ray = makeRayThatIntersectsColumn(column: column)

        // The starting map coordinate
        var mapCoordinateX = Int(cameraPosition.x)
        var mapCoordinateY = Int(cameraPosition.y)

        // The direction we step through the map.
        let wallStepX = (ray.x < 0) ? -1 : 1
        let wallStepY = (ray.y < 0) ? -1 : 1

        // The length of the ray from one x-side to next x-side and y-side to next y-side
        let deltaDistanceX = sqrt(1.0 + (ray.y * ray.y) / (ray.x * ray.x))
        let deltaDistanceY = sqrt(1.0 + (ray.x * ray.x) / (ray.y * ray.y))

        // Current length along the ray we've marched, from starting to the next x-side or y-side
        var distanceX = (ray.x < 0) ? (cameraPosition.x - Float(mapCoordinateX)) * deltaDistanceX :
                                          (Float(mapCoordinateX) + 1.0 - cameraPosition.x) * deltaDistanceX
        var distanceY = (ray.y < 0) ? (cameraPosition.y - Float(mapCoordinateY)) * deltaDistanceY :
                                          (Float(mapCoordinateY) + 1.0 - cameraPosition.y) * deltaDistanceY

        // Let's track if we hit the x-side or y-side?
        var isSideHit = false

        // March along the ray until we hit a wall
        while worldMap[mapCoordinateX][mapCoordinateY] <= 0 {
            if distanceX < distanceY {
                distanceX += deltaDistanceX
                mapCoordinateX += wallStepX
                isSideHit = false
            } else {
                distanceY += deltaDistanceY
                mapCoordinateY += wallStepY
                isSideHit = true
            }
        }

        // We've hit a wall. Get the distance of the wall from the camera
        var wallDistance: Float = 0.0
        if isSideHit == false {
            wallDistance = (Float(mapCoordinateX) - cameraPosition.x + (1.0 - Float(wallStepX)) / 2.0) / ray.x
        } else {
            wallDistance = (Float(mapCoordinateY) - cameraPosition.y + (1.0 - Float(wallStepY)) / 2.0) / ray.y
        }

        // Using the wall distance, calculate the height of the column to draw values to draw
        let lineHeight = Int(Float(height) / wallDistance)
        let yStartPixel = -lineHeight / 2 + height / 2
        let yEndPixel = lineHeight / 2 + height / 2

        // Get the texture data for the wall we hit
        let texture = worldMap[mapCoordinateX][mapCoordinateY] == 1 ? stoneWallTexture : brickWallTexture

        // Calculate the x point on the wall that was hit so we can get the appropriate texture data
        var wallHitPositionX = isSideHit ? cameraPosition.x + wallDistance * ray.x :
                                           cameraPosition.y + wallDistance * ray.y

        wallHitPositionX -= floor((wallHitPositionX))

        // Go through and draw each pixel in the column into our output
        let wallHitPositionStartY = Float(height) / 2.0 - Float(lineHeight) / 2.0
        for yPixel in yStartPixel..<yEndPixel {
            let wallHitPositionY = (Float(yPixel) - wallHitPositionStartY) / Float(lineHeight)
            let textureXPos = Int(wallHitPositionX * Float(texture.count))
            let textureYPos = Int(wallHitPositionY * Float(texture[0].count))

            let color = texture[textureXPos][textureYPos]
            output[yPixel][column] = color * (isSideHit ? 0.5 : 1.0)
        }
    }

    func loadTextureData(fileName: String) -> [[Color]] {
        guard let image =  UIImage(named: fileName) else {
            return [[Color]]()
        }

        if let pixelData = image.cgImage?.dataProvider?.data {
            var output = [[Color]]()
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

            for xPos in 0..<Int(image.size.width) {
                var colorRow = [Color]()

                for yPos in 0..<(Int(image.size.height)) {
                    let pixelInfo = (Int(image.size.width) * yPos + xPos) * 4

                    let red = Float(data[pixelInfo+0]) / 255.0
                    let green = Float(data[pixelInfo+1]) / 255.0
                    let blue = Float(data[pixelInfo+2]) / 255.0
                    colorRow.append(Color(red: red, green: green, blue: blue))
                }
                output.append(colorRow)
            }

            return output
        } else {
            return [[Color]]()
        }
    }
}
