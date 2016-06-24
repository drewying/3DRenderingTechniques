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
    @IBOutlet weak var renderView: RenderView!
    
    var triangles:[Triangle] = Array<Triangle>()
    var zBuffer:[[Float]] = Array<Array<Float>>()
    var timer: CADisplayLink! = nil
    let lightPosition:Vector3D = Vector3D(x: 1.0, y: 1.0, z: 1.0)
    let cameraPosition:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 5.0)
    var currentRotation:Float = 0.0
    
    
    //Matrices
    var modelMatrix:Matrix = Matrix.identityMatrix()
    var projectionMatrix:Matrix = Matrix.identityMatrix()
    var viewMatrix:Matrix = Matrix.identityMatrix()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadTeapot()
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
    
    func renderLoop(){
        let startTime:NSDate = NSDate()
        updateMatrices()
        zBuffer = Array<Array<Float>>(count: renderView.width, repeatedValue: Array<Float>(count: renderView.height, repeatedValue: FLT_MAX))
        renderView.clear()
        for triangle:Triangle in triangles{
            renderTriangle(triangle)
        }
        renderView.render()
        currentRotation += 0.02
        print(String(1.0 / Float(-startTime.timeIntervalSinceNow)) + " FPS")
        
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
    
    func updateMatrices(){
        modelMatrix = Matrix.rotateY(-currentRotation) * Matrix.rotateX(0.65) * Matrix.translate(Vector3D(x: 0.0, y: -0.4, z: 0.0))
        viewMatrix = Matrix.lookAt(cameraPosition, cameraTarget: Vector3D(x: 0, y: 0, z: 0), cameraUp: Vector3D.up())
        projectionMatrix = Matrix.perspective(0.78, aspectRatio: Float(renderView.width)/Float(renderView.height), zNear: -1.0, zFar: 1.0)
        
    }
    
    func plotScanLine(y:Int, p0:Vector3D, p1:Vector3D, p2:Vector3D, p3:Vector3D, c0:Color8, c1:Color8, c2:Color8, c3:Color8){
        let leftDistance = p0.y != p1.y ? (Float(y) - p0.y) / (p1.y - p0.y) : 1.0;
        let rightDistance = p2.y != p3.y ? (Float(y) - p2.y) / (p3.y - p2.y) : 1.0;
        
        //Calculate the left and start
        var xStart = Int(interpolate(p0.x, max: p1.x, distance: leftDistance));
        var xEnd = Int(interpolate(p2.x, max: p3.x, distance: rightDistance));
        
        var zStart:Float = interpolate(p0.z, max: p1.z, distance: leftDistance);
        var zEnd:Float = interpolate(p2.z, max: p3.z, distance: rightDistance);
        
        var cStart:Color8 = interpolate(c0, max: c1, distance: leftDistance);
        var cEnd:Color8 = interpolate(c2, max: c3, distance: rightDistance);
        
        if (xEnd < xStart){
            //Swap start with end variables
            xStart += xEnd; xEnd = xStart - xEnd; xStart -= xEnd
            zStart += zEnd; zEnd = zStart - zEnd; zStart -= zEnd
            
            let tempColor = cStart
            cStart = cEnd
            cEnd = tempColor
        }
        
        for x in xStart ..< xEnd {
            let horizontalDistance = Float(x - xStart) / Float(xEnd - xStart);
            let z = interpolate(zStart, max: zEnd, distance: horizontalDistance);
            let color = interpolate(cStart, max: cEnd, distance: horizontalDistance);
            if (x >= 0 && y >= 0 && x < renderView.width && y < renderView.height){
                if (z < zBuffer[x][y]){
                    renderView.plot(x, y: y, color: color)
                    zBuffer[x][y] = z
                }
            }
            
        }
        
    }
        
    func renderTriangle(triangle:Triangle){
        
        var p0 = triangle.p0 * (modelMatrix * viewMatrix)
        var p1 = triangle.p1 * (modelMatrix * viewMatrix)
        var p2 = triangle.p2 * (modelMatrix * viewMatrix)
        
        if ((p0 - cameraPosition) ⋅ ((p1 - p0) × (p2 - p0)) >= 0){
            return;
        }
        
        let normalMatrix = Matrix.transpose(Matrix.inverse(modelMatrix * viewMatrix))
        let n0 = Matrix.transformPoint(normalMatrix, right: triangle.n0).normalized()
        let n1 = Matrix.transformPoint(normalMatrix, right: triangle.n1).normalized()
        let n2 = Matrix.transformPoint(normalMatrix, right: triangle.n2).normalized()
        
        //Calculate Lighting
        //var l0:Float = calculateLightingFactor(lightPosition, targetPosition: p0, targetNormal: n0)
        //var l1:Float = calculateLightingFactor(lightPosition, targetPosition: p1, targetNormal: n1)
        //var l2:Float = calculateLightingFactor(lightPosition, targetPosition: p2, targetNormal: n2)
        
        let diffuseColor:Color8 = Color8(a: 255, r: 128, g: 0, b: 0)
        let ambientColor:Color8 = Color8(a: 255, r: 30, g: 30, b: 30)
        let lightColor:Color8 = Color8(a: 255, r: 255, g: 255, b: 255)
        
        var c0:Color8 = calculatePhongLightingFactor(lightPosition, targetPosition: p0, targetNormal: n0, diffuseColor: diffuseColor, ambientColor: ambientColor, shininess: 4.0, lightColor: lightColor)
        var c1:Color8 = calculatePhongLightingFactor(lightPosition, targetPosition: p1, targetNormal: n1, diffuseColor: diffuseColor, ambientColor: ambientColor, shininess: 4.0, lightColor: lightColor)
        var c2:Color8 = calculatePhongLightingFactor(lightPosition, targetPosition: p2, targetNormal: n2, diffuseColor: diffuseColor, ambientColor: ambientColor, shininess: 4.0, lightColor: lightColor)
        
        p0 = projectPoint(p0 * projectionMatrix)
        p1 = projectPoint(p1 * projectionMatrix)
        p2 = projectPoint(p2 * projectionMatrix)
        
        let points:[(Vector3D, Color8)] = [(p0,c0), (p1,c1), (p2,c2)].sort {
            return $0.0.y < $1.0.y
        }
        
        p0 = points[0].0
        p1 = points[1].0
        p2 = points[2].0
        c0 = points[0].1
        c1 = points[1].1
        c2 = points[2].1
        
        
        var topSlope:Float = 0
        if (p1.y - p0.y > 0){
            topSlope = (p1.x - p0.x) / (p1.y - p0.y);
        }
        
        var bottomSlope:Float = 0
        if (p2.y - p0.y > 0){
           bottomSlope = (p2.x - p0.x) / (p2.y - p0.y);
        }
        
        // First case where triangles are like that:
        // P0
        // -
        // --
        // - -
        // -  -
        // -   - P1
        // -  -
        // - -
        // -
        // P2
        
        if (topSlope > bottomSlope)
        {
            for y in Int(p0.y)...Int(p2.y) {
                if (Float(y) < p1.y) {
                    plotScanLine(y, p0: p0, p1: p2, p2: p0, p3: p1, c0: c0, c1: c2, c2: c0, c3: c1);
                } else {
                    plotScanLine(y, p0: p0, p1: p2, p2: p1, p3: p2, c0: c0, c1: c2, c2: c1, c3: c2);
                }
            }
        }
            // First case where triangles are like that:
            //       P0
            //        -
            //       --
            //      - -
            //     -  -
            // P1 -   -
            //     -  -
            //      - -
            //        -
            //       P2
        else {
            for y in Int(p0.y)...Int(p2.y) {
                if (Float(y) < p1.y) { //Plot top half
                    plotScanLine(y, p0: p0, p1: p1, p2: p0, p3: p2, c0: c0, c1: c1, c2: c0, c3: c2);
                } else { //Plot bottom half
                    plotScanLine(y, p0: p1, p1: p2, p2: p0, p3: p2, c0: c1, c1: c2, c2: c0, c3: c2);
                }
            }
        }
        
        
    }
    
    func projectPoint(point:Vector3D) -> Vector3D{
        let x = point.x * Float(renderView.width) + Float(renderView.width) / 2.0;
        let y = point.y * Float(renderView.height) + Float(renderView.height) / 2.0;
        return Vector3D(x: x, y: y, z: point.z)
    }
    
    func fragmentShader(point:Vector3D, shadowFactor:Float) -> Color8 {
        let value = 255 * clamp(shadowFactor)
        return Color8(a: 255, r:UInt8(value)/3, g: UInt8(value)/2, b: UInt8(value)/2)
    }

    
    
}
