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
    var timer: CADisplayLink! = nil
    
    let worldMap:[[Int]] =
        [[1,1,1,1,1,1,1],
        [1,1,0,0,0,1,1],
        [1,0,0,0,0,0,1],
        [1,0,0,0,0,0,1],
        [1,0,0,0,0,0,1],
        [1,1,0,0,0,1,1],
        [1,1,1,1,1,1,1]]
    var currentRotation:Float = 0.0
    
    func renderLoop(){
        let startTime:NSDate = NSDate()
        
        renderView.clear()
        
        for x:Int in 0 ..< renderView.width {
            drawColumn(x)
        }
        
        renderView.render()
        currentRotation += 0.02
        print(String(1.0 / Float(-startTime.timeIntervalSinceNow)) + " FPS")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        timer = CADisplayLink(target: self, selector: #selector(RasterizationViewController.renderLoop))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }
    
    func drawColumn(x:Int){
       
        let direction:Vector3D = Vector3D(x: -1.0, y: 0.0, z: 0.0) * Matrix.rotateZ(currentRotation)
        let plane:Vector3D = Vector3D(x: 0.0, y: 0.5, z: 0.0) * Matrix.rotateZ(currentRotation)
        
        let cameraX:Float = 2.0 * Float(x) / Float(renderView.width) - 1.0;
        let rayOrigin:Vector3D = Vector3D(x: 3.5, y: 3.5, z: 0.0)
        let rayDirection:Vector3D = Vector3D(x: direction.x + plane.x * cameraX, y: direction.y + plane.y * cameraX, z: 0.0)
        

        let deltaDistanceX:Float = rayDirection.x == 0 ? FLT_MAX : sqrt(1.0 + (rayDirection.y * rayDirection.y) / (rayDirection.x * rayDirection.x))
        let deltaDistanceY:Float = rayDirection.y == 0 ? FLT_MAX : sqrt(1.0 + (rayDirection.x * rayDirection.x) / (rayDirection.y * rayDirection.y))
        
        let mapWidth:Int = worldMap.count
        let mapHeight:Int = worldMap[0].count
        
        var mapCoordinateX:Int = Int(rayOrigin.x)
        var mapCoordinateY:Int = Int(rayOrigin.y)
        
        var wallStepX:Int = 0
        var wallStepY:Int = 0
        
        var sideDistanceX:Float = 0.0
        var sideDistanceY:Float = 0.0
        
        if (rayDirection.x < 0){
            wallStepX = -1
            sideDistanceX = (rayOrigin.x - Float(mapCoordinateX)) * deltaDistanceX
        } else {
            wallStepX = 1
            sideDistanceX = (Float(mapCoordinateX) + 1.0 - rayOrigin.x) * deltaDistanceX
        }
        
        if (rayDirection.y < 0){
            wallStepY = -1
            sideDistanceY = (rayOrigin.y - Float(mapCoordinateY)) * deltaDistanceY
        } else {
            wallStepY = 1
            sideDistanceY = (Float(mapCoordinateY) + 1.0 - rayOrigin.y) * deltaDistanceY
        }
        
        var hitWall:Bool = false
        var isSideHit:Bool = false
        
        while (!hitWall){
            if (sideDistanceX < sideDistanceY){
                sideDistanceX += deltaDistanceX
                mapCoordinateX += wallStepX
                isSideHit = false;
            } else {
                sideDistanceY += deltaDistanceY
                mapCoordinateY += wallStepY
                isSideHit = true;
            }
            if (mapCoordinateX < 0 || mapCoordinateY < 0 || mapCoordinateX > mapWidth || mapCoordinateY > mapHeight){
                hitWall = true
            } else if (worldMap[mapCoordinateX][mapCoordinateY] > 0){
                hitWall = true
            }
        }
        
        var wallDistance:Float = 0.0
        
        if (!isSideHit){
            wallDistance = (Float(mapCoordinateX) - rayOrigin.x + (1.0 - Float(wallStepX)) / 2.0) / rayDirection.x;
        } else {
            wallDistance = (Float(mapCoordinateY) - rayOrigin.y + (1.0 - Float(wallStepY)) / 2.0) / rayDirection.y;
        }
        
        let lineHeight:Int = Int(Float(renderView.width) / wallDistance)
        
        let yStartPixel = -lineHeight / 2 + renderView.height / 2;
        let yEndPixel = lineHeight / 2 + renderView.height / 2;
        
        let color:Color8 = Color8(a: 255, r: 192, g: 100, b: 50) * (isSideHit ? 0.5 : 1.0)
        for y in yStartPixel ..< yEndPixel {
            renderView.plot(x, y: y, color: color)
        }
        
    }
    
}
