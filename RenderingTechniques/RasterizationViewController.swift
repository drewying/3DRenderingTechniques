//
//  RasterizationViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/8/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct Point {
    var x:Float
    var y:Float
    var z:Float
}

struct Triangle {
    var p0:Point
    var p1:Point
    var p2:Point
}

class RasterizationViewController: UIViewController {

    @IBOutlet weak var mainImageView: UIImageView!
    
    var pixelData:PixelData = PixelData(width: 0, height: 0)
    var triangles:[Triangle] = Array<Triangle>()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        pixelData = PixelData(width: Int(mainImageView.bounds.size.width), height: Int(mainImageView.bounds.size.height))
        
        loadTeapot()
        NSLog("Beginning Render")
        for triangle:Triangle in triangles{
            plotTriangle(triangle)
            //plotTriangleLines(triangle)
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
                var points:[Point] = Array<Point>()
                
                for line:String in lines{
                    if (line.hasPrefix("v ")){
                        let values:[String] = line.componentsSeparatedByString(" ")
                        points.append(Point(x: (values[1] as NSString).floatValue, y: (values[2] as NSString).floatValue, z: (values[3] as NSString).floatValue))
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
                // contents could not be loaded
            }
        } else {
            // example.txt not found!
        }
    }

    func plotTopFlatTriangle(p0:Point, p1:Point, p2:Point){
        let inverseSlope0:Float = (p2.x - p0.x) / (p2.y - p0.y)
        let inverseSlope1:Float = (p2.x - p1.x) / (p2.y - p1.y)
        
        var currentX0:Float = p2.x
        var currentX1:Float = p2.x
        
        for y in (Int(p0.y + 1)...Int(p2.y)).reverse(){
            
            let start = Int(min(currentX0, currentX1))
            let end = Int(max(currentX0, currentX1))
            
            for x in (start...end){
                let color:PixelColor = fragmentShader(Point(x: Float(x), y: Float(y), z: p1.z))
                pixelData.plot(x, y: y, pixelColor: color)
            }
            currentX0 -= inverseSlope0
            currentX1 -= inverseSlope1
        }
    }
    
    func plotBottomFlatTriangle(p0:Point, p1:Point, p2:Point){
        let inverseSlope0:Float = (p1.x - p0.x) / (p1.y - p0.y)
        let inverseSlope1:Float = (p2.x - p0.x) / (p2.y - p0.y)
    
        var currentX0:Float = p0.x
        var currentX1:Float = p0.x
    
        for y in Int(p0.y)...Int(p1.y){

            let start = Int(min(currentX0, currentX1))
            let end = Int(max(currentX0, currentX1))
            
            for x in (start...end){
                let color:PixelColor = fragmentShader(Point(x: Float(x), y: Float(y), z: p1.z))
                pixelData.plot(x, y: y, pixelColor: color)
            }
            currentX0 += inverseSlope0
            currentX1 += inverseSlope1
        }
    }
   
    func plotTriangleLines(triangle:Triangle){
         plotLine(triangle.p0, p1: triangle.p1)
         plotLine(triangle.p1, p1: triangle.p2)
         plotLine(triangle.p2, p1: triangle.p0)
    }

    
    func plotTriangle(triangle:Triangle){
        
        
        var p0:Point = triangle.p0
        if (triangle.p1.y > p0.y){
            p0 = triangle.p1
        }
        if (triangle.p2.y > p0.y){
            p0 = triangle.p2
        }
        
        var p2:Point = triangle.p0;
        if (triangle.p1.y < p2.y){
            p2 = triangle.p1
        }
        if (triangle.p2.y < p2.y){
            p2 = triangle.p2
        }
        
        var p1:Point = triangle.p0
        if (p1.y == p0.y || p1.y == p2.y){
            p1 = triangle.p1;
        }
        if (p1.y == p0.y || p1.y == p2.y){
            p1 = triangle.p2;
        }
        
        p0 = projectPoint(p0)
        p1 = projectPoint(p1)
        p2 = projectPoint(p2)
        
        /* check for trivial case of bottom-flat triangle */
        if (Int(p1.y) == Int(p2.y)) {
            plotBottomFlatTriangle(p0, p1: p1, p2: p2);
        } else if (Int(p0.y) == Int(p1.y)) { /* check for trivial case of top-flat triangle */
            plotTopFlatTriangle(p0, p1: p1, p2: p2);
        } else { /* general case - split the triangle in a topflat and bottom-flat one */
            let p3 = Point(x: (p0.x + ((p1.y - p0.y) / (p2.y - p0.y)) * (p2.x - p0.x)), y: p1.y, z: p1.z);
            plotBottomFlatTriangle(p0, p1: p1, p2: p3);
            plotTopFlatTriangle(p1, p1: p3, p2: p2);
        }
        
        
        
    }
    
    func plotLine(p0:Point, p1:Point){
        let projectedPoint0:Point = projectPoint(p0)
        let projectedPoint1:Point = projectPoint(p1)
        
        var x0:Int = Int(projectedPoint0.x);
        let x1:Int = Int(projectedPoint1.x);
        
        var y0:Int = Int(projectedPoint0.y);
        let y1:Int = Int(projectedPoint1.y);
        
        let deltaX:Float = Float(abs(x1 - x0))
        let incrementX:Int = x0 < x1 ? 1 : -1;
        let deltaY:Float = Float(abs(y1 - y0))
        let incrementY:Int = y0 < y1 ? 1 : -1;
        var error:Float = (deltaX > deltaY ? deltaX : -deltaY)/2.0;
        
        while (true) {
            pixelData.plot(x0, y: y0, pixelColor:PixelColor(a: 255, r: 255, g: 0, b: 0))
            if (x0 == x1 && y0 == y1){
                return;
            }
            
            let error2:Float = error;
            
            if (error2 > -deltaX){
                error -= deltaY;
                x0 += incrementX;
            }
            
            if (error2 < deltaY){
                error += deltaX;
                y0 += incrementY;
            }
        }
    }
    
    func projectPoint(point:Point) -> Point{
        let p:Point = vertexShader(point);
        let maxViewPortSize:Float = Float(max(pixelData.width, pixelData.height))
        let x:Float = ((p.x * maxViewPortSize + maxViewPortSize) / 2.0)
        let y:Float = ((-p.y * maxViewPortSize + maxViewPortSize) / 2.0)
        //let x:Float = ((p.x * Float(pixelData.width) + Float(pixelData.width)) / 2.0)
        //let y:Float = ((-p.y * Float(pixelData.height) + Float(pixelData.height)) / 2.0)
        return Point(x: round(x), y: round(y), z: -p.z)
    }
    
    func vertexShader(point:Point) -> Point{
        return point;
    }
    
    func fragmentShader(point:Point) -> PixelColor {
        var value = 255 * ((point.z + 1.0)/2.0)
        return PixelColor(a: 255, r:UInt8(value), g: 0, b: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
}
