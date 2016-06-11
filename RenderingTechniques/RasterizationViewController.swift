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
    
    var n0:Vector3D
    var n1:Vector3D
    var n2:Vector3D
}

class RasterizationViewController: UIViewController {

    @IBOutlet weak var mainImageView: UIImageView!
    
    var pixelData:PixelData = PixelData(width: 0, height: 0)
    var triangles:[Triangle] = Array<Triangle>()
    var zBuffer:[[Float]] = Array<Array<Float>>()
    let lightPosition:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 2.0)
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        pixelData = PixelData(width: Int(mainImageView.bounds.size.width), height: Int(mainImageView.bounds.size.height))
        zBuffer = Array<Array<Float>>(count: pixelData.width, repeatedValue: Array<Float>(count: pixelData.height, repeatedValue: FLT_MIN))
        
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
        //if let filepath = NSBundle.mainBundle().pathForResource("cube", ofType: "obj") {
            do {
                let contents:String = try NSString(contentsOfFile: filepath, usedEncoding: nil) as String
                let lines:[String] = contents.componentsSeparatedByString("\n")
                var points:[Vector3D] = Array<Vector3D>()
                var normals:[Vector3D] = Array<Vector3D>()
                
                for line:String in lines{
                    if (line.hasPrefix("v ")){
                        let values:[String] = line.componentsSeparatedByString(" ")
                        points.append(Vector3D(x: (values[1] as NSString).floatValue, y: (values[2] as NSString).floatValue, z: (values[3] as NSString).floatValue))
                    }
                    if (line.hasPrefix("vn ")){
                        let values:[String] = line.componentsSeparatedByString(" ")
                        normals.append(Vector3D(x: (values[1] as NSString).floatValue, y: (values[2] as NSString).floatValue, z: (values[3] as NSString).floatValue))
                    }
                    if (line.hasPrefix("f ")){
                        let values:[String] = line.componentsSeparatedByString(" ")
                        let i0:Int = (values[1].substringToIndex((values[1].rangeOfString("//")?.startIndex)!) as NSString).integerValue - 1
                        let in0:Int = (values[1].substringFromIndex((values[1].rangeOfString("//")?.endIndex)!) as NSString).integerValue - 1
                        let i1:Int = (values[2].substringToIndex((values[2].rangeOfString("//")?.startIndex)!) as NSString).integerValue - 1
                        let in1:Int = (values[2].substringFromIndex((values[2].rangeOfString("//")?.endIndex)!) as NSString).integerValue - 1
                        let i2:Int = (values[3].substringToIndex((values[3].rangeOfString("//")?.startIndex)!) as NSString).integerValue - 1
                        let in2:Int = (values[3].substringFromIndex((values[3].rangeOfString("//")?.endIndex)!) as NSString).integerValue - 1
                        triangles.append(Triangle(p0: points[i0], p1: points[i1], p2: points[i2], n0: normals[in0], n1: normals[in1], n2: normals[in2]))
                    }
                }
            } catch {
                print("Couldn't load teapot")
            }
        } else {
            print("Couldn't load teapot")
        }
    }
   
    func clamp(value:Float) -> Float{
        return max(0.0, min(value, 1.0));
    }
    
    func interpolate(min:Float, max:Float, delta:Float) -> Float{
        return min + (max - min) * clamp(delta);
    }
    
    func plotScanLine(y:Int, p0:Vector3D, p1:Vector3D, p2:Vector3D, p3:Vector3D, n0:Vector3D, n1:Vector3D, n2:Vector3D, n3:Vector3D){
        let leftSlope = p0.y != p1.y ? (Float(y) - p0.y) / (p1.y - p0.y) : 1.0;
        let rightSlope = p2.y != p3.y ? (Float(y) - p2.y) / (p3.y - p2.y) : 1.0;
        
        //Calculate the left and start
        var xStart = Int(interpolate(p0.x, max: p1.x, delta: leftSlope));
        var xEnd = Int(interpolate(p2.x, max: p3.x, delta: rightSlope));
        
        var zStart:Float = interpolate(p0.z, max: p1.z, delta: leftSlope);
        var zEnd:Float = interpolate(p2.z, max: p3.z, delta: rightSlope);
        
        let l0 = n0 ⋅ lightPosition
        let l1 = n1 ⋅ lightPosition
        let l2 = n2 ⋅ lightPosition
        let l3 = n3 ⋅ lightPosition
        
        var lStart:Float = interpolate(l0, max: l1, delta: leftSlope);
        var lEnd:Float = interpolate(l2, max: l3, delta: rightSlope);
        
        if (xEnd < xStart){
            let temp = xStart
            xStart = xEnd
            xEnd = temp
            
            let ztemp = zStart
            zStart = zEnd
            zEnd = ztemp
            
            let ltemp = lStart
            lStart = lEnd
            lEnd = ltemp
            
        }
        
        for x in xStart ..< xEnd {
            let horizontalSlope = Float(x - xStart) / Float(xEnd - xStart);
            let z = interpolate(zStart, max: zEnd, delta: horizontalSlope);
            let l = interpolate(lStart, max: lEnd, delta: horizontalSlope);
            if (z > zBuffer[x][y]){
                let color:PixelColor = fragmentShader(Vector3D(x: Float(x), y: Float(y), z: z), shadowFactor: l)
                pixelData.plot(x, y: y, pixelColor: color)
                zBuffer[x][y] = z
            }
            
        }
        
    }
    
    func renderTriangle(triangle:Triangle){
        
        //Project the points into pixel coordinates
        /*var points:[Vector3D] = [projectPoint(triangle.p0), projectPoint(triangle.p1), projectPoint(triangle.p2)];
        
        //Sort points by the y coordinates
        points.sortInPlace {
            if Int($0.y) == Int($1.y){
                return $0.x < $1.x
            } else {
                return $0.y < $1.y
            }
        }
        
        //Draw the projected Triangle to screen
        
        var projectedTriangle = triangle
        projectedTriangle.p0 = points[0]
        projectedTriangle.p1 = points[1]
        projectedTriangle.p2 = points[2]
        
        let p0:Vector3D = projectedTriangle.p0
        let p1:Vector3D = projectedTriangle.p1
        let p2:Vector3D = projectedTriangle.p2
        
        let n0:Vector3D = projectedTriangle.n0
        let n1:Vector3D = projectedTriangle.n1
        let n2:Vector3D = projectedTriangle.n2*/
        
        var p0 = projectPoint(triangle.p0)
        var p1 = projectPoint(triangle.p1)
        var p2 = projectPoint(triangle.p2)
        var n0 = projectPoint(triangle.n0)
        var n1 = projectPoint(triangle.n1)
        var n2 = projectPoint(triangle.n2)
        
        if (p0.y > p1.y){
            var temp = p1;
            p1 = p0;
            p0 = temp;
        
            temp = n1;
            n1 = n0;
            n0 = temp;
        }
        
        if (p1.y > p2.y){
            var temp = p1;
            p1 = p2;
            p2 = temp;
            
            temp = n1;
            n1 = n2;
            n2 = temp;
        }
        
        if (p0.y > p1.y){
            var temp = p1;
            p1 = p0;
            p0 = temp;
            
            temp = n1;
            n1 = n0;
            n0 = temp;
        }
        
        var topSlope:Float = 0
        if (p1.y - p0.y > 0){
            topSlope = (p1.x - p0.x) / (p1.y - p0.y);
        }
        
        var bottomSlope:Float = 0
        if (p2.y - p0.y > 0){
           bottomSlope = (p2.x - p0.x) / (p2.y - p0.y);
        }
        
        // First case where triangles are like that:
        // P1
        // -
        // --
        // - -
        // -  -
        // -   - P2
        // -  -
        // - -
        // -
        // P3
        
        if (topSlope > bottomSlope)
        {
            for y in Int(p0.y)...Int(p2.y) {
                if (Float(y) < p1.y) {
                    plotScanLine(y, p0: p0, p1: p2, p2: p0, p3: p1, n0: n0, n1: n2, n2: n0, n3: n1);
                } else {
                    plotScanLine(y, p0: p0, p1: p2, p2: p1, p3: p2, n0: n0, n1: n2, n2: n1, n3: n2);
                }
            }
        }
            // First case where triangles are like that:
            //       P1
            //        -
            //       --
            //      - -
            //     -  -
            // P2 -   -
            //     -  -
            //      - -
            //        -
            //       P3
        else {
            for y in Int(p0.y)...Int(p2.y) {
                if (Float(y) < p1.y) {
                    plotScanLine(y, p0: p0, p1: p1, p2: p0, p3: p2, n0: n0, n1: n1, n2: n0, n3: n2);
                } else {
                    plotScanLine(y, p0: p1, p1: p2, p2: p0, p3: p2, n0: n1, n1: n2, n2: n0, n3: n2);
                }
            }
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
        let matrix:Matrix =  Matrix.translate(Vector3D(x: 0.0, y: 0.25, z: 0.0)) * Matrix.scale(Vector3D(x: 0.5, y: 0.5, z: 0.5)) * Matrix.rotateX(-0.35)// * Matrix.rotateY(0.785)
        return matrix * point
    }
    
    func fragmentShader(point:Vector3D, shadowFactor:Float) -> PixelColor {
        let value = 255 * clamp(shadowFactor)
        //let pos = Vector3D(x: point.x/Float(pixelData.width), y: point.y/Float(pixelData.height), z: point.z)
        //let value = 255 * clamp((Vector3D(x: 0, y: 0, z: 1.0) ⋅ pos.normalized()) * 4)
        //let value = 255 * clamp((point.z + 1.0)/2.0)
        return PixelColor(a: 255, r:UInt8(value)/3, g: UInt8(value)/2, b: UInt8(value))
    }

    
    
}
