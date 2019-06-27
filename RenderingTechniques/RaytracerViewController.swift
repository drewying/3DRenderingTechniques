//
//  RaytracerViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/15/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

class RaytracerViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    @IBOutlet weak var fpsLabel: UILabel!
    
    var timer: CADisplayLink! = nil
    var samplenumber:Int = 0
    let cameraPosition = Vector3D(x: 0.0, y: 0.0, z: -3.0)
    let cameraUp = Vector3D.up()
    let lightPosition = Vector3D(x: 0.0, y: 0.9, z: 0.0)
    var sceneObjects:[Sphere] = Array<Sphere>()
    var colorBuffer:[Color] = Array<Color>();
    var currentRotation:Float = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.renderView.clear()
        self.colorBuffer = [Color](repeating:Color(r: 0.0, g: 0.0, b: 0.0), count: self.renderView.width * self.renderView.height)
        self.samplenumber = 0
        self.renderView.width = Int(Float(self.renderView.width) * 0.75)
        self.renderView.height = Int(Float(self.renderView.height) * 0.75)
        
        timer = CADisplayLink(target: self, selector: #selector(renderLoop))
        timer.add(to: .current, forMode: .common)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }
    
    @objc func renderLoop() {
        let startTime:NSDate = NSDate()
        drawScreen()
        renderView.render()
        samplenumber += 1
        self.fpsLabel.text = String(format: "%.1 FPS", 1.0 / Float(-startTime.timeIntervalSinceNow))
    }
    
    func drawScreen(){
        for x in 0..<renderView.width {
            for y in 0..<renderView.height {
                //Generate a ray that passes through the pixel at (x, y)
                let ray:Ray = makeRayThatIntersectsPixel(x: x, y: y)
                //Trace that ray and determine the color
                let newColor = traceRay(ray: ray, bounceIteration: 0)
                //Mix the new color with the current known color.
                let currentColor = colorBuffer[y * renderView.width + x]
                let mixedColor = ((currentColor * Float(samplenumber)) + newColor)  *  (1.0/Float(samplenumber + 1))
                colorBuffer[y * renderView.width + x] = mixedColor
                renderView.plot(x: x, y: y, color: mixedColor)
            }
        }
    }
    
    func traceRay(ray:Ray, bounceIteration:Int) -> Color {

        //We've bounced the ray around the scene 5 times. Return.
        if (bounceIteration >=  5){
            return Color(r: 0.0, g: 0.0, b: 0.0)
        }
        
        //Go through each sceneObject and find the closest sceneObject the ray intersects
        var closestObject:Sphere = sceneObjects[0]
        var closestHitRecord:HitRecord = HitRecord.noHit()
        
        for sceneObject:Sphere in sceneObjects {
            let hitRecord:HitRecord = sceneObject.checkRayIntersection(ray: ray)
            if (hitRecord.hitSuccess && hitRecord.hitDistance < closestHitRecord.hitDistance){
                closestHitRecord = hitRecord
                closestObject = sceneObject
            }
        }
        
        //Create a new ray to gather more information about the scene
        var nextRay = ray;
        switch closestObject.material {
        case Material.DIFFUSE:
            nextRay = ray.bounceRay(origin: closestHitRecord.hitPosition, normal: closestHitRecord.hitNormal)
            break
        case Material.REFLECTIVE:
            nextRay = ray.reflectRay(origin: closestHitRecord.hitPosition, normal: closestHitRecord.hitNormal)
            break
        case Material.REFRACTIVE:
            nextRay = ray.refractRay(origin: closestHitRecord.hitPosition, normal: closestHitRecord.hitNormal)
            break
        }
    
        //Gather color and lighting data about both this hit as well as the next one
        return traceRay(ray: nextRay, bounceIteration: bounceIteration + 1) * closestObject.color + closestObject.emission
    }
    
    func makeRayThatIntersectsPixel(x:Int, y:Int) -> Ray{
        //Convert pixel coordinates to world coordinate
        let fieldOfView:Float = 0.785
        let scale:Float = tanf(fieldOfView * 0.5)
        let aspectRatio:Float = Float(renderView.width)/Float(renderView.height)
        let dx = 1.0 / Float(renderView.width)
        let dy = 1.0 / Float(renderView.height)
        
        var cameraX = (2 * (Float(x) + 0.5) * dx - 1) * aspectRatio * scale
        var cameraY = (1 - 2 * (Float(y) + 0.5) * dy) * scale * -1
        
        //Randomly move the ray up or down to create anti-aliasing
        let r1 = Float(arc4random()) / Float(UINT32_MAX)
        let r2 = Float(arc4random()) / Float(UINT32_MAX)
        cameraX += (r1 - 0.5)/Float(renderView.width)
        cameraY += (r2 - 0.5)/Float(renderView.height)

        //Transform the world coordinate into a ray
        let lookAt = -cameraPosition.normalized()
        let eyeVector = (lookAt - cameraPosition).normalized()
        let rightVector = (eyeVector × cameraUp)
        let upVector = (eyeVector × rightVector)
        let rayDirection = (eyeVector + rightVector * cameraX + upVector * cameraY).normalized()
        
        return Ray(origin: cameraPosition, direction: rayDirection)
    }
    
    func setupScene(){
        
        let leftWall:Sphere = Sphere(center: Vector3D(x: -10e3, y: 0.0, z: 0.0),
                                     radius: 10e3 - 1.0,
                                     color: Color(r: 0.9, g: 0.5, b: 0.5),
                                     emission: Color(r: 0.0, g: 0.0, b: 0.0),
                                     material:Material.DIFFUSE )
        
        let rightWall:Sphere = Sphere(center: Vector3D(x: 10e3, y: 0.0, z: 0.0),
                                   radius: 10e3 - 1.0,
                                   color: Color(r: 0.5, g: 0.5, b: 0.9),
                                   emission: Color(r: 0.0, g: 0.0, b: 0.0),
                                   material:Material.DIFFUSE )
        
        let frontWall:Sphere = Sphere(center: Vector3D(x: 0.0, y: 0.0, z: 10e3),
                                     radius: 10e3 - 2.0,
                                     color: Color(r: 0.9, g: 0.9, b: 0.9),
                                     emission: Color(r: 0.0, g: 0.0, b: 0.0),
                                     material:Material.DIFFUSE )
        
        let backWall:Sphere = Sphere(center: Vector3D(x: 0.0, y: 0.0, z: -10e3),
                                      radius: 10e3 - 3.0,
                                      color: Color(r: 0.9, g: 0.9, b: 0.9),
                                      emission: Color(r: 0.0, g: 0.0, b: 0.0),
                                      material:Material.DIFFUSE )
        
        let topWall:Sphere = Sphere(center: Vector3D(x: 0.0, y: 10e3, z: 0.0),
                                    radius: 10e3 - 1.0,
                                    color: Color(r: 0.0, g: 0.0, b: 0.0),
                                    emission: Color(r: 1.6, g: 1.47, b: 1.29),
                                    material:Material.DIFFUSE )
        

        let bottomWall:Sphere = Sphere(center: Vector3D(x: 0.0, y: -10e3, z: 0.0),
                                    radius: 10e3 - 1.0,
                                    color: Color(r: 0.8, g: 0.8, b: 0.8),
                                    emission: Color(r: 0.0, g: 0.0, b: 0.0),
                                    material:Material.DIFFUSE )
        
        let mirrorSphere:Sphere = Sphere(center: Vector3D(x: -0.5, y: -0.7, z: 0.7),
                                         radius: 0.3,
                                         color: Color(r: 0.8, g: 0.8, b: 0.8),
                                         emission: Color(r: 0.0, g: 0.0, b: 0.0),
                                         material:Material.REFLECTIVE )
        
        let glassSphere:Sphere = Sphere(center: Vector3D(x: 0.5, y: -0.65, z: 0.25),
                                        radius: 0.35,
                                        color: Color(r: 1.0, g: 1.0, b: 1.0),
                                        emission: Color(r: 0.0, g: 0.0, b: 0.0),
                                        material:Material.REFRACTIVE )
        
        sceneObjects =  [leftWall, rightWall, topWall, bottomWall, frontWall, backWall, glassSphere, mirrorSphere]
        
    }

}

enum Material {
    case DIFFUSE
    case REFLECTIVE
    case REFRACTIVE
}

struct Ray {
    let origin:Vector3D;
    let direction:Vector3D;
    
    func bounceRay(origin:Vector3D, normal:Vector3D) -> Ray{
        let u1:Float = Float(arc4random()) / Float(UINT32_MAX)
        let u2:Float = Float(arc4random()) / Float(UINT32_MAX)
        
        let uu:Vector3D = (normal × Vector3D(x: 0.0, y: 1.0, z: 1.0)).normalized()
        let vv:Vector3D = uu × normal
        
        let r:Float = sqrt(u1);
        let theta:Float = 2 * .pi * u2;
        
        let x:Float = r * cos(theta);
        let y:Float = r * sin(theta);
        let z:Float = sqrt(1.0 - u1);
        
        let bounceDirection = x * uu + y * vv + z * normal
        return Ray(origin: origin, direction: bounceDirection.normalized() )
        
    }
    
    func reflectRay(origin:Vector3D, normal:Vector3D) -> Ray {
        let cosine = direction ⋅ normal
        let reflectDirection = self.direction - (normal * 2.0 * cosine)
        return Ray(origin: origin, direction: reflectDirection.normalized())
    }
    
    func refractRay(origin:Vector3D, normal:Vector3D) -> Ray {
        let theta1 = abs(direction ⋅ normal);
        
        var internalIndex:Float = 1.0
        var externalIndex:Float = 1.5
        
        if (theta1 >= 0.0) {
            internalIndex = 1.5
            externalIndex = 1.0
        }
        
        let eta:Float = externalIndex/internalIndex;
        let theta2:Float = sqrt(1.0 - (eta * eta) * (1.0 - (theta1 * theta1)));
        let rs:Float = (externalIndex * theta1 - internalIndex * theta2) / (externalIndex*theta1 + internalIndex * theta2);
        let rp:Float = (internalIndex * theta1 - externalIndex * theta2) / (internalIndex*theta1 + externalIndex * theta2);
        let reflectance:Float = (rs*rs + rp*rp);
        
        // Check for perfect refraction (Reflection)
        if(Float(arc4random()) / Float(UINT32_MAX) < reflectance) {
            return reflectRay(origin:origin, normal: normal)
        }
       
        let refractDirection = ((direction + (normal * theta1)) * eta) + (normal * -theta2)
        return Ray(origin: origin, direction: refractDirection.normalized())
    }
}

struct HitRecord {
    let hitSuccess:Bool
    let hitPosition:Vector3D
    let hitNormal:Vector3D
    let hitDistance:Float
    
    static func noHit() -> HitRecord{
        return HitRecord(hitSuccess: false, hitPosition: Vector3D(x: 0, y: 0, z: 0), hitNormal: Vector3D(x: 0, y: 0, z: 0), hitDistance: Float.greatestFiniteMagnitude)
    }
}

struct Sphere {
    var center:Vector3D
    let radius:Float
    var color:Color
    var emission: Color
    var material: Material
    
    func checkRayIntersection(ray:Ray) -> HitRecord {
        let v:Vector3D = center - ray.origin
        let b:Float = v ⋅ ray.direction
        let discriminant:Float = b * b - (v ⋅ v) + radius * radius;
        
        if (discriminant < 0) {
            return HitRecord.noHit()
        }
        
        let d:Float = sqrt(discriminant);
        let tFar:Float = b + d;
        let tNear:Float = b - d;
        
        if (tFar <= 0.001 && tNear <= 0.001) {
            return HitRecord.noHit()
        }
        
        let hitDistance = (tNear <= 0.001 ? tFar : tNear)
        let hitPosition = ray.origin + ray.direction * hitDistance
        let hitNormal = (hitPosition - center).normalized()
        
        return HitRecord(hitSuccess: true, hitPosition: hitPosition, hitNormal: hitNormal, hitDistance: hitDistance)
    }
}
