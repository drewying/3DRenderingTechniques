//
//  RasterizationViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/8/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct Triangle {
    var p0:Vector3D
    var p1:Vector3D
    var p2:Vector3D
}

class RasterizationViewController: UIViewController {

    @IBOutlet weak var mainImageView: UIImageView!
    
    var pixelData:PixelData = PixelData(width: 0, height: 0)
    var triangles:[Triangle] = Array<Triangle>()
    var zBuffer:[[Float]] = Array<Array<Float>>()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        pixelData = PixelData(width: Int(mainImageView.bounds.size.width), height: Int(mainImageView.bounds.size.height))
        zBuffer = Array<Array<Float>>(count: pixelData.width, repeatedValue: Array<Float>(count: pixelData.height, repeatedValue: -100.0))
        
        loadTeapot()
        NSLog("Beginning Render")
        for triangle:Triangle in triangles{
            renderTriangle(triangle)
        }
        mainImageView.image = pixelData.getImageRepresentation()
        NSLog("Render Finished")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func loadTeapot(){
        if let filepath = NSBundle.mainBundle().pathForResource("teapot", ofType: "obj") {
            do {
                let contents:String = try NSString(contentsOfFile: filepath, usedEncoding: nil) as String
                let lines:[String] = contents.componentsSeparatedByString("\n")
                var points:[Vector3D] = Array<Vector3D>()
                
                for line:String in lines{
                    if (line.hasPrefix("v ")){
                        let values:[String] = line.componentsSeparatedByString(" ")
                        points.append(Vector3D(x: (values[1] as NSString).floatValue, y: (values[2] as NSString).floatValue, z: (values[3] as NSString).floatValue))
                    }
                    if (line.hasPrefix("f ")){
                        let values:[String] = line.componentsSeparatedByString(" ")
                        let i0:Int = (values[1].substringToIndex((values[1].rangeOfString("//")?.startIndex)!) as NSString).integerValue - 1
                        let i1:Int = (values[2].substringToIndex((values[2].rangeOfString("//")?.startIndex)!) as NSString).integerValue - 1
                        let i2:Int = (values[3].substringToIndex((values[3].rangeOfString("//")?.startIndex)!) as NSString).integerValue - 1
                        triangles.append(Triangle(p0: points[i0], p1: points[i1], p2: points[i2]))
                    }
                }
            } catch {
                print("Couldn't load teapot")
            }
        } else {
            print("Couldn't load teapot")
        }
    }

    func plotTopFlatTriangle(p0:Vector3D, p1:Vector3D, p2:Vector3D){
        let inverseSlope0:Float = (p2.x - p0.x) / (p2.y - p0.y)
        let inverseSlope1:Float = (p2.x - p1.x) / (p2.y - p1.y)
        
        let inverseSlopeZ0:Float = (p2.z - p0.z) / (p2.y - p0.y)
        let inverseSlopeZ1:Float = (p2.z - p1.z) / (p2.y - p1.y)
        
        var currentX0:Float = p2.x
        var currentX1:Float = p2.x
        
        var currentZ0:Float = p2.z
        var currentZ1:Float = p2.z
        
        for y in (Int(p0.y + 1)...Int(p2.y)).reverse(){
            
            let xStart = Int(min(currentX0, currentX1))
            let xEnd = Int(max(currentX0, currentX1))
            
            let zStart = currentZ0
            let zEnd = currentZ1
            
            plotHorizontalLine(xStart, xEnd: xEnd, y: y, zStart:zStart, zEnd:zEnd)
            
            currentX0 -= inverseSlope0
            currentX1 -= inverseSlope1
            
            currentZ0 -= inverseSlopeZ0
            currentZ1 -= inverseSlopeZ1
        }
    }
    
    func plotBottomFlatTriangle(p0:Vector3D, p1:Vector3D, p2:Vector3D){
        let inverseSlope0:Float = (p1.x - p0.x) / (p1.y - p0.y)
        let inverseSlope1:Float = (p2.x - p0.x) / (p2.y - p0.y)
        
        let inverseSlopeZ0:Float = (p1.z - p0.z) / (p1.y - p0.y)
        let inverseSlopeZ1:Float = (p2.z - p0.z) / (p2.y - p0.y)
        
        var currentX0:Float = p0.x
        var currentX1:Float = p0.x
        
        var currentZ0:Float = p0.z
        var currentZ1:Float = p0.z
        
        for y in Int(p0.y)...Int(p1.y){

            
            let xStart = Int(min(currentX0, currentX1))
            let xEnd = Int(max(currentX0, currentX1))
            
            let zStart = currentZ0
            let zEnd = currentZ1
            
            plotHorizontalLine(xStart, xEnd: xEnd, y: y, zStart:zStart, zEnd:zEnd)
            
            currentX0 += inverseSlope0
            currentX1 += inverseSlope1
            
            currentZ0 += inverseSlopeZ0
            currentZ1 += inverseSlopeZ1
            
        }
    }
   
    func plotHorizontalLine(xStart:Int, xEnd:Int, y:Int, zStart:Float, zEnd:Float){
        let inverseSlopeZ:Float = (zEnd - zStart) / Float(xEnd - xStart);
        for x in (xStart...xEnd){
            let z:Float = zStart + (Float(x - xStart) * inverseSlopeZ)
            if (x >= 0 && y >= 0 && x < pixelData.width && y < pixelData.height){
                if (z >= zBuffer[x][y]){
                    let color:PixelColor = fragmentShader(Vector3D(x: Float(x), y: Float(y), z: z))
                    pixelData.plot(x, y: y, pixelColor: color)
                    zBuffer[x][y] = z
                }
            }
            
        }
    }
    
    func renderTriangle(triangle:Triangle){
        
        //Project the points into pixel coordinates
        var points:[Vector3D] = [projectPoint(triangle.p0), projectPoint(triangle.p1), projectPoint(triangle.p2)];
        
        //Sort points by the y coordinates
        points.sortInPlace {
            if Int($0.y) == Int($1.y){
                return $0.x < $1.x
            } else {
                return $0.y < $1.y
            }
        }
        
        //Draw the projected Triangle to screen
        let p0 = points[0]
        let p1 = points[1]
        let p2 = points[2]
        
        
        if (Int(p1.y) == Int(p2.y)) { //Check if we have a Bottom Flat Triangle
            plotBottomFlatTriangle(p0, p1: p1, p2: p2);
        } else if (Int(p0.y) == Int(p1.y)) { //Check if we have a Top Flat Triangle
            plotTopFlatTriangle(p0, p1: p1, p2: p2);
        } else { //Split the triangle into a top and a bottom and go crazy.
            let p3 = Vector3D(x: (p0.x + ((p1.y - p0.y) / (p2.y - p0.y)) * (p2.x - p0.x)), y: p1.y, z: p1.z);
            plotBottomFlatTriangle(p0, p1: p1, p2: p3);
            plotTopFlatTriangle(p1, p1: p3, p2: p2);
        }
        
        
        
    }
    
    func projectPoint(point:Vector3D) -> Vector3D{
        let p:Vector3D = vertexShader(point);
        let maxViewPortSize:Float = Float(max(pixelData.width, pixelData.height))
        let x:Float = ((p.x * maxViewPortSize + maxViewPortSize) / 2.0)
        let y:Float = ((-p.y * maxViewPortSize + maxViewPortSize) / 2.0)
        return Vector3D(x: round(x), y: round(y), z: -p.z)
    }
    
    func vertexShader(point:Vector3D) -> Vector3D{
        let matrix:Matrix = Matrix.translate(Vector3D(x: 0.0, y: 0.25, z: 0.0)) * Matrix.scale(Vector3D(x: 0.5, y: 0.5, z: 0.5)) * Matrix.rotateY(0.5)
        return point * matrix //matrix * point
    }
    
    func fragmentShader(point:Vector3D) -> PixelColor {
        let value = 255 * ((point.z + 1.0)/2.0)
        return PixelColor(a: 255, r:UInt8(value), g: 0, b: 0)
    }

    
    
}
