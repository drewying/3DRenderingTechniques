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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pixelData = PixelData(width: Int(mainImageView.bounds.size.width), height: Int(mainImageView.bounds.size.height))
        
        loadTeapot()
        NSLog("Beginning Render")
        for triangle:Triangle in triangles{
            plotTriangle(triangle)
        }
        mainImageView.image = pixelData.getImageRepresentation()
        NSLog("Render Finished")
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
                        let i1:Int = (values[2].substringToIndex((values[1].rangeOfString("//")?.startIndex)!) as NSString).integerValue - 1
                        let i2:Int = (values[3].substringToIndex((values[1].rangeOfString("//")?.startIndex)!) as NSString).integerValue - 1
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

    func plotTriangle(triangle:Triangle){
        plotLine(triangle.p0, p1: triangle.p1)
        plotLine(triangle.p1, p1: triangle.p2)
        plotLine(triangle.p2, p1: triangle.p0)
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
            pixelData.plot(x0, y: y0, red: 255, green: 0, blue: 0, alpha: 255)
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
        let x:Float = ((point.x * Float(pixelData.width) + Float(pixelData.width)) / 2.0)
        let y:Float = ((-point.y * Float(pixelData.height) + Float(pixelData.height)) / 2.0)
        return Point(x: x, y: y, z: -point.z)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
}
