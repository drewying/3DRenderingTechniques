//
//  RasterizationViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/8/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct Triangle {
    var v0:Vertex
    var v1:Vertex
    var v2:Vertex
}

struct Vertex {
    var point:Vector3D
    var normal:Vector3D
}


class RasterizationViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    @IBOutlet weak var fpsLabel: UILabel!
    var timer: CADisplayLink! = nil
    
    let lightPosition:Vector3D = Vector3D(x: 1.0, y: 1.0, z: 1.0)
    let cameraPosition:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 5.0)
    
    var currentRotation:Float = 0.0
    var triangles:[Triangle] = Array<Triangle>()
    var zBuffer:[[Float]] = Array<Array<Float>>()
    
    //Matrices
    var modelMatrix:Matrix = Matrix.identityMatrix()
    var perspectiveMatrix:Matrix = Matrix.identityMatrix()
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
        self.fpsLabel.text = String(format: "%.1 FPS", 1.0 / Float(-startTime.timeIntervalSinceNow))
        
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
                        
                        let v0:Vertex = Vertex(point: points[i0], normal: normals[in0])
                        let v1:Vertex = Vertex(point: points[i1], normal: normals[in1])
                        let v2:Vertex = Vertex(point: points[i2], normal: normals[in2])
                        
                        triangles.append(Triangle(v0: v0, v1: v1, v2: v2))
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
        //The model matrix is the matrix that's responsible for positioning the model in world space
        modelMatrix = Matrix.rotateY(-currentRotation) * Matrix.rotateX(0.65) * Matrix.translate(Vector3D(x: 0.0, y: -0.4, z: 0.0))
        //The view matrix transforms from world space into camera space
        viewMatrix = Matrix.lookAt(cameraPosition, cameraTarget: Vector3D(x: 0, y: 0, z: 0), cameraUp: Vector3D.up())
        //The perspective matrix adds the illusion of perspective
        perspectiveMatrix = Matrix.perspective(0.78, aspectRatio: Float(renderView.width)/Float(renderView.height), zNear: -1.0, zFar: 1.0)
        
    }
    
    func renderTriangle(triangle:Triangle){
        
        var v0 = triangle.v0
        var v1 = triangle.v1
        var v2 = triangle.v2
        
        //Transform the vertices of the triangle with the three matrices.
        v0.point = v0.point * modelMatrix * viewMatrix * perspectiveMatrix
        v1.point = v1.point * modelMatrix * viewMatrix * perspectiveMatrix
        v2.point = v2.point * modelMatrix * viewMatrix * perspectiveMatrix
        
        /*//Check if the triangle is visible to the camera. If not, don't render it.
        if ((p0 - cameraPosition) ⋅ ((p1 - p0) × (p2 - p0)) >= 0){
            return;
        }*/
        
        //Sort the Vertices from top to bottom
        let vertices:[Vertex] = [v0, v1, v2].sort {
            return $0.point.y < $1.point.y
        }
        
        v0 = vertices[0]
        v1 = vertices[1]
        v2 = vertices[2]
        
        //Project the three points of the triangle into screen space, and add transform the points for perspective.
        //This fulfills the role of the typical vertext shader.
        v0.point = projectPoint(v0.point)
        v1.point = projectPoint(v1.point)
        v2.point = projectPoint(v2.point)
       
        //Calculate the topslop and bottom slop of the triangle
        let topSlope:Float = (v1.point.y - v0.point.y > 0) ? (v1.point.x - v0.point.x) / (v1.point.y - v0.point.y) : 0
        let bottomSlope:Float = (v2.point.y - v0.point.y > 0) ?  (v2.point.x - v0.point.x) / (v2.point.y - v0.point.y) : 0
       
        
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
            
            for y in Int(v0.point.y)...Int(v1.point.y) {
                let leftDistance = (v2.point.y == v0.point.y) ? 0 : (Float(y) - v0.point.y) / (v2.point.y - v0.point.y)
                let rightDistance = (v1.point.y == v0.point.y) ? 0 : (Float(y) - v0.point.y) / (v1.point.y - v0.point.y)
                
                let leftPoint = interpolate(v0.point, max:v2.point, distance: leftDistance)
                let rightPoint = interpolate(v0.point, max:v1.point, distance: rightDistance)
                
                let leftNormal = interpolate(v0.normal, max:v2.normal, distance: leftDistance)
                let rightNormal = interpolate(v0.normal, max:v1.normal, distance: rightDistance)
                
                let leftVertex = Vertex(point: leftPoint, normal: leftNormal)
                let rightVertex = Vertex(point: rightPoint, normal: rightNormal)
                
                plotScanLine(y, left: leftVertex, right: rightVertex)
                
            }
            
            for y in Int(v1.point.y)...Int(v2.point.y) {
                let leftDistance = (v2.point.y == v0.point.y) ? 0 : (Float(y) - v0.point.y) / (v2.point.y - v0.point.y)
                let rightDistance = (v2.point.y == v1.point.y) ? 0 : (Float(y) - v1.point.y) / (v2.point.y - v1.point.y)
                
                let leftPoint = interpolate(v0.point, max:v2.point, distance: leftDistance)
                let rightPoint = interpolate(v1.point, max:v2.point, distance: rightDistance)
                
                let leftNormal = interpolate(v0.normal, max:v2.normal, distance: leftDistance)
                let rightNormal = interpolate(v1.normal, max:v2.normal, distance: rightDistance)
                
                let leftVertex = Vertex(point: leftPoint, normal: leftNormal)
                let rightVertex = Vertex(point: rightPoint, normal: rightNormal)
                
                plotScanLine(y, left: leftVertex, right: rightVertex)
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
            for y in Int(v0.point.y)...Int(v1.point.y) {
                let leftDistance = (v1.point.y == v0.point.y) ? 0 : (Float(y) - v0.point.y) / (v1.point.y - v0.point.y)
                let rightDistance = (v2.point.y == v0.point.y) ? 0 : (Float(y) - v0.point.y) / (v2.point.y - v0.point.y)
                
                let leftPoint = interpolate(v0.point, max:v1.point, distance: leftDistance)
                let rightPoint = interpolate(v0.point, max:v2.point, distance: rightDistance)
                
                let leftNormal = interpolate(v0.normal, max:v1.normal, distance: leftDistance)
                let rightNormal = interpolate(v0.normal, max:v2.normal, distance: rightDistance)
                
                let leftVertex = Vertex(point: leftPoint, normal: leftNormal)
                let rightVertex = Vertex(point: rightPoint, normal: rightNormal)
                
                plotScanLine(y, left: leftVertex, right: rightVertex)
                
            }
            
            for y in Int(v1.point.y)...Int(v2.point.y) {
                let leftDistance =  (v2.point.y == v1.point.y) ? 0 : (Float(y) - v1.point.y) / (v2.point.y - v1.point.y)
                let rightDistance = (v2.point.y == v0.point.y) ? 0 : (Float(y) - v0.point.y) / (v2.point.y - v0.point.y)
                
                let leftPoint = interpolate(v1.point, max:v2.point, distance: leftDistance)
                let rightPoint = interpolate(v0.point, max:v2.point, distance: rightDistance)
                
                let leftNormal = interpolate(v1.normal, max:v2.normal, distance: leftDistance)
                let rightNormal = interpolate(v0.normal, max:v2.normal, distance: rightDistance)
                
                let leftVertex = Vertex(point: leftPoint, normal: leftNormal)
                let rightVertex = Vertex(point: rightPoint, normal: rightNormal)
                
                plotScanLine(y, left: leftVertex, right: rightVertex)
            }
        }
        
        
    }
    
    func plotScanLine(y:Int, left:Vertex, right:Vertex){
   
        var start = left
        var end = right
        
        if (left.point.x > right.point.x){
            swap(&start, &end)
        }
        
        for x in Int(start.point.x) ..< Int(end.point.x) {
            let horizontalDistance = (Float(x) - start.point.x) / (end.point.x - start.point.x);
            let point = interpolate(start.point, max: end.point, distance: horizontalDistance);
            let normal = interpolate(start.normal, max: end.normal, distance: horizontalDistance);
            
            if (x >= 0 && y >= 0 && x < renderView.width && y < renderView.height){
                if (point.z < zBuffer[x][y]){
                    let tPoint = unprojectPoint(point) * Matrix.inverse(perspectiveMatrix)
                    let vertext = Vertex(point: tPoint, normal: normal)
                    let color = shader(vertext) //Color(r: 0.5, g: 0.0, b: 0.0) //shader(Vector3D(x: Float(x/renderView.width) , y: Float(y/renderView.height), z: z) * Matrix.inverse(perspectiveMatrix), normal: normal)
                    renderView.plot(x, y: y, color: color)
                    zBuffer[x][y] = point.z
                }
            }
            
        }
        
    }
    
    func unprojectPoint(point:Vector3D) -> Vector3D{
        let x = ((point.x / Float(renderView.width)) * 2.0) - 1.0
        let y = ((point.y / Float(renderView.height)) * 2.0) - 1.0
        return Vector3D(x: x, y: y, z: point.z)
    }
    
    func projectPoint(point:Vector3D) -> Vector3D{
        let x = point.x * Float(renderView.width) + Float(renderView.width) / 2.0;
        let y = point.y * Float(renderView.height) + Float(renderView.height) / 2.0;
        return Vector3D(x: x, y: y, z: point.z)
    }
    
    func shader(vertex:Vertex) -> Color{
        //Calculate the color of the pixel at each
        let normalMatrix = Matrix.transpose(Matrix.inverse(modelMatrix * viewMatrix))
        let normal = Matrix.transformPoint(normalMatrix, right: vertex.normal).normalized()
        
        let diffuseColor:Color = Color(r: 0.5, g: 0, b: 0)
        let ambientColor:Color = Color(r: 0.33, g: 0.33, b: 0.33)
        let lightColor:Color = Color(r: 1.0, g: 1.0, b: 1.0)
        
        return calculatePhongLightingFactor(lightPosition, targetPosition: vertex.point, targetNormal: normal, diffuseColor: diffuseColor, ambientColor: ambientColor, shininess: 4.0, lightColor: lightColor)
    }
    
}
