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
    
    let playerPosition:Vector2D = Vector2D(x: 3.5, y: 3.5)
    let worldMap:[[Int]] =
       [[1,1,2,2,2,1,1],
        [1,0,2,0,2,1,1],
        [1,0,0,0,0,0,1],
        [1,0,0,0,0,0,1],
        [1,0,0,0,0,0,1],
        [2,2,0,0,0,2,2],
        [2,2,1,1,1,2,2]]
    
    @objc func renderLoop(){
        let startTime:NSDate = NSDate()
        
        renderView.clear()
        
        for x:Int in 0 ..< renderView.width {
            drawColumn(x: x)
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
    
    func drawColumn(x:Int){
       
        let viewDirection:Vector2D = Vector2D(x: -1.0, y: 0.0).rotate(angle: currentRotation)
        let plane:Vector2D = Vector2D(x: 0.0, y: 0.5).rotate(angle: currentRotation)
        
        let cameraX:Float = 2.0 * Float(x) / Float(renderView.width) - 1.0;
        let rayDirection:Vector2D = Vector2D(x: viewDirection.x + plane.x * cameraX, y: viewDirection.y + plane.y * cameraX)
        
        //The starting map coordinate
        var mapCoordinateX:Int = Int(playerPosition.x)
        var mapCoordinateY:Int = Int(playerPosition.y)
        
        //The direction we step through the map.
        let wallStepX:Int = (rayDirection.x < 0) ? -1 : 1
        let wallStepY:Int = (rayDirection.y < 0) ? -1 : 1
        
        //The length of the ray from one x-side to next x-side and y-side to next y-side
        let deltaDistanceX:Float = rayDirection.x == 0 ? Float.greatestFiniteMagnitude : sqrt(1.0 + (rayDirection.y * rayDirection.y) / (rayDirection.x * rayDirection.x))
        let deltaDistanceY:Float = rayDirection.y == 0 ? Float.greatestFiniteMagnitude : sqrt(1.0 + (rayDirection.x * rayDirection.x) / (rayDirection.y * rayDirection.y))
        
        //Length of ray from player to next x-side or y-side
        var sideDistanceX:Float = (rayDirection.x < 0) ? (playerPosition.x - Float(mapCoordinateX)) * deltaDistanceX : (Float(mapCoordinateX) + 1.0 - playerPosition.x) * deltaDistanceX
        var sideDistanceY:Float = (rayDirection.y < 0) ? (playerPosition.y - Float(mapCoordinateY)) * deltaDistanceY : (Float(mapCoordinateY) + 1.0 - playerPosition.y) * deltaDistanceY
        
        //Did we hit the x-side or y-side?
        var isSideHit:Bool = false
        
        //Find the next wall intersection by checking the x and y sides along the direction of the ray.
        while (worldMap[mapCoordinateX][mapCoordinateY] <= 0){
            if (sideDistanceX < sideDistanceY){
                sideDistanceX += deltaDistanceX
                mapCoordinateX += wallStepX
                isSideHit = false;
            } else {
                sideDistanceY += deltaDistanceY
                mapCoordinateY += wallStepY
                isSideHit = true;
            }
        }
        
        //Get the wall distance
        var wallDistance:Float = 0.0
        if (!isSideHit){
            wallDistance = (Float(mapCoordinateX) - playerPosition.x + (1.0 - Float(wallStepX)) / 2.0) / rayDirection.x;
        } else {
            wallDistance = (Float(mapCoordinateY) - playerPosition.y + (1.0 - Float(wallStepY)) / 2.0) / rayDirection.y;
        }
        
        //Get the beginning and ending y pixel values to draw
        let lineHeight:Int = Int(Float(renderView.height) / wallDistance)
        let yStartPixel = -lineHeight / 2 + renderView.height / 2;
        let yEndPixel = lineHeight / 2 + renderView.height / 2;
        
        //Get the texture data for thw all
        let texture = worldMap[mapCoordinateX][mapCoordinateY] == 1 ? stoneWallTextureData : redBrickTextureData
        
        //Calculate the x point on the wall that was hit
        var wallHitPositionX:Float = 0.0
        if (!isSideHit){
            wallHitPositionX = playerPosition.y + wallDistance * rayDirection.y;
        } else {
            wallHitPositionX = playerPosition.x + wallDistance * rayDirection.x;
        }
        
        wallHitPositionX -= floor((wallHitPositionX));
        
        //Go through and plot each pixel in the column
        let wallHitPositionStartY:Float = Float(renderView.height) / 2.0 - Float(lineHeight) / 2.0
        for y in yStartPixel ..< yEndPixel {
            let wallHitPositionY:Float = (Float(y) - wallHitPositionStartY) / Float(lineHeight)
            let color = texture.getPixelColor(x: Int(wallHitPositionX * Float(textureWidth)), y: Int(wallHitPositionY * Float(textureHeight)))
            renderView.plot(x: x, y: y, color: color * (isSideHit ? 0.5 : 1.0))
        }
    }
}

extension UIImage {
    
    func getPixelColor(x:Int, y:Int) -> Color {
        
        if let pixelData = self.cgImage?.dataProvider?.data {
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            
            let pixelInfo: Int = (Int(self.size.width) * y + x) * 4
            
            let r = Float(data[pixelInfo+0]) / 255.0
            let g = Float(data[pixelInfo+1]) / 255.0
            let b = Float(data[pixelInfo+2]) / 255.0
            
            return Color(r: r, g: g, b: b)
        } else {
            //IF something is wrong I returned WHITE, but change as needed
            return Color(r: 0, g: 0, b: 0)
        }
    }
}
