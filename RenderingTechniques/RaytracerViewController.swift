//
//  RaytracerViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/15/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct Ray {
    let origin:Vector3D;
    let direction:Vector3D;
}

protocol SceneObject{
    func checkRayIntersection(ray:Ray, inout t:Float, inout normal:Vector3D, inout hitPosition:Vector3D) -> Bool
}

struct Sphere : SceneObject {
    let center:Vector3D
    let radius:Float
    let color:Color8
    
    func checkRayIntersection(ray:Ray, inout t:Float, inout normal:Vector3D, inout hitPosition:Vector3D) -> Bool {
        let v:Vector3D = center - ray.origin
        let b:Float = v ⋅ ray.direction
        let discriminant:Float = b * b - (v ⋅ v) + radius * radius;
        if (discriminant < 0) {
            return false
        }
        
        let d:Float = sqrt(discriminant);
        let tFar:Float = b + d;
        let tNear:Float = b - d;
        
        if (tFar <= 0.001 && tNear <= 0.001) {
            return false;
        }
        
        if (tNear <= 0.001) {
            t = tFar
        } else {
            t = tNear
        }
        
        hitPosition = ray.origin + ray.direction * t;
        normal = (hitPosition - center).normalized()
        return true
    }
}

class RaytracerViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    
    let cameraPosition = Vector3D(x: 0.0, y: 0.0, z: -2.0)
    let cameraUp = Vector3D.up()
    let lightPosition = Vector3D(x: 0.0, y: 0.0, z: -1.0)
    var sceneObjects:[SceneObject] = Array<SceneObject>()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        renderLoop()
    }
    
    func renderLoop() {
        renderView.clear()
        let s:Sphere = Sphere(center: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.2, color: Color8(a: 255, r: 0, g: 255, b: 0))
        let s1:Sphere = Sphere(center: Vector3D(x: 0.5, y: 0.0, z: 0.5), radius: 0.1, color: Color8(a: 255, r: 255, g: 0, b: 0))
        
        sceneObjects.append(s)
        sceneObjects.append(s1)
        
        for x:Int in 0 ..< renderView.width {
            for y:Int in 0 ..< renderView.height {
                let fieldOfView:Float = 1.571 //90 degrees in Radians
                let scale:Float = tanf(fieldOfView * 0.5)
                
                let aspectRatio:Float = Float(renderView.width)/Float(renderView.height)
                
                
    
                let dx = 1.0 / Float(renderView.width)
                let dy = 1.0 / Float(renderView.height)
                let cameraX = (2 * (Float(x) + 0.5) * dx - 1) * scale
                let cameraY = (1 - 2 * (Float(y) + 0.5) * dy) * scale * 1 / aspectRatio
                
                //var cameraX = (2 * (Float(x) + 0.5) * dx - 1) * aspectRatio * scale;
                //var cameraY = (1 - 2 * (Float(y) + 0.5) * dx) * scale;
                //var cameraX = (-0.5 + Float(x)  * dx) * scale
                //var cameraY = (-0.5 + Float(y)  * dy) * scale * 1 / aspectRatio
                
                
                let ray:Ray = makeRay(cameraX, y: cameraY)
                var maxDistance:Float = FLT_MAX
                var normal:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 0.0)
                var hitPosition:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 0.0)
                for sceneObject in sceneObjects {
                    var currentDistance:Float = FLT_MAX
                    if (sceneObject.checkRayIntersection(ray, t: &currentDistance, normal: &normal, hitPosition: &hitPosition)){
                        if (currentDistance < maxDistance){
                            maxDistance = currentDistance;
                            let sphere = sceneObject as! Sphere
                            let color:Color8 = sphere.color * calculateLightingFactor(hitPosition, normal: normal)
                            renderView.plot(x, y: y, color: color)
                        }
                    }
                }
                
                
            }
        }
        renderView.render()
    }
    
    func calculateLightingFactor(point:Vector3D, normal:Vector3D) -> Float{
        let lightDistance = (lightPosition - point).length()
        let lightVector = (lightPosition - point).normalized()
        var lightFactor = max((lightVector ⋅ normal), 0.25)
        lightFactor *= (1.0 / (1.0 + (0.25 * lightDistance * lightDistance)))
        return lightFactor
    }
    
    func makeRay(x:Float, y:Float) -> Ray{
        
        let lookAt = -cameraPosition.normalized()
        let eyeVector = lookAt - cameraPosition
        let rightVector = (eyeVector × cameraUp).normalized()
        let upVector = (eyeVector × rightVector).normalized()
        
        //var aspectRatio:Float = Float(renderView.width)/Float(renderView.height)
        //rightVector = rightVector * aspectRatio
        
        var rayDirection = eyeVector + rightVector * x + upVector * y;
        rayDirection = rayDirection.normalized()
        
        return Ray(origin: cameraPosition, direction: rayDirection)
    }

}
