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
    
    var timer: CADisplayLink! = nil
    
    let cameraPosition = Vector3D(x: 0.0, y: 0.0, z: -0.9)
    let cameraUp = Vector3D.up()
    let lightPosition = Vector3D(x: 0.0, y: 0.0, z: -0.5)
    var sceneObjects:[SceneObject] = Array<SceneObject>()

    var mirrorSphere:Sphere = Sphere(center: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.25, color: Color8(a: 255, r: 255, g: 255, b: 255), shininess:100.0, material:Material.REFLECTIVE )
    var glassSphere:Sphere = Sphere(center: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.25, color: Color8(a: 255, r: 255, g: 255, b: 255), shininess:100.0, material:Material.REFRACTIVE )
    let diffuseSphere:Sphere = Sphere(center: Vector3D(x: 0.0, y: 0.0, z: 0.25), radius: 0.2, color: Color8(a: 255, r: 0, g: 255, b: 0), shininess:800.0, material:Material.DIFFUSE )
    
    var currentRotation:Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
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
    
    func renderLoop() {
        let startTime:NSDate = NSDate()
        renderView.clear()
        drawScreen()
        renderView.render()
        glassSphere.center = Vector3D(x: 0.5, y: 0.0, z:0.0) * Matrix.rotateY(currentRotation) * Matrix.translate(Vector3D(x: 0.0, y: 0.0, z: 0.5))
        mirrorSphere.center = Vector3D(x: -0.5, y: 0.0, z:0.0) * Matrix.rotateY(currentRotation) * Matrix.translate(Vector3D(x: 0.0, y: 0.0, z: 0.5))
        sceneObjects[6] = glassSphere
        sceneObjects[7] = mirrorSphere
        currentRotation += 0.2
        print(String(1.0 / Float(-startTime.timeIntervalSinceNow)) + " FPS")
    }
    
    func drawScreen(){
        let fieldOfView:Float = 1.57 //90 degrees in Radians
        let scale:Float = tanf(fieldOfView * 0.5)
        let aspectRatio:Float = Float(renderView.width)/Float(renderView.height)
        let dx = 1.0 / Float(renderView.width)
        let dy = 1.0 / Float(renderView.height)
        
        for x:Int in 0 ..< renderView.width {
            for y:Int in 0 ..< renderView.height {
                let cameraX = (2 * (Float(x) + 0.5) * dx - 1) * aspectRatio * scale
                let cameraY = (1 - 2 * (Float(y) + 0.5) * dy) * scale * -1
                
                let ray:Ray = makeRay(cameraX, y: cameraY)
                let color = castRay(ray)
                renderView.plot(x, y: y, color: color)
            }
        }
    }
    
    func castRay(ray:Ray) -> Color8 {
        
        var normal:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 0.0)
        var hitPosition:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 0.0)
        var currentDistance = FLT_MAX
    
        var closestSceneObject:SceneObject = sceneObjects[0]
        var closestHit:Vector3D = hitPosition
        var closestNormal:Vector3D = normal;
        
        for sceneObject in sceneObjects {
            var distance:Float = FLT_MAX
            if (sceneObject.checkRayIntersection(ray, t: &distance, normal: &normal, hitPosition: &hitPosition)){
                if (distance < currentDistance){
                    currentDistance = distance
                    closestSceneObject = sceneObject
                    closestNormal = normal
                    closestHit = hitPosition
                }
            }
        }
        
        switch closestSceneObject.material {
            case Material.DIFFUSE:
                return calculatePhongLightingFactor(lightPosition, targetPosition: closestHit, targetNormal: closestNormal, diffuseColor: closestSceneObject.color, ambientColor: Color8(a: 255, r: 30, g: 30, b: 30), shininess: closestSceneObject.shininess, lightColor: Color8(a: 255, r: 255, g: 255, b: 255))
            case Material.REFLECTIVE:
                let reflectedRay = ray.reflectRay(closestHit, normal: closestNormal)
                return castRay(reflectedRay)
            case Material.REFRACTIVE:
                let refractedRay:Ray = ray.refractRay(closestHit, normal: closestNormal)
                return castRay(refractedRay)
        }
        
    }
    
    /*func castRay(ray:Ray) -> Color8{
        var outColor = Color8(a: 255, r: 0, g: 0, b: 0)
        var maxDistance:Float = FLT_MAX
        var normal:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 0.0)
        var hitPosition:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 0.0)
        
        for sceneObject in sceneObjects {
            var currentDistance:Float = FLT_MAX
            if (sceneObject.checkRayIntersection(ray, t: &currentDistance, normal: &normal, hitPosition: &hitPosition)){
                if (currentDistance < maxDistance){
                    maxDistance = currentDistance;
                    switch sceneObject.material {
                    case Material.DIFFUSE:
                        outColor = sceneObject.color * calculateLightingFactor(lightPosition, targetPosition:hitPosition, targetNormal: normal)
                        break
                    case Material.REFLECTIVE:
                        let reflectedRay = ray.reflectRay(hitPosition, normal: normal)
                        outColor = castRay(reflectedRay)
                        break
                    case Material.REFRACTIVE:
                        let refractedRay:Ray = ray.refractRay(hitPosition, normal: normal)
                        outColor = castRay(refractedRay)
                        break
                    }
                }
            }
        }
        return outColor
    }*/
    
    func makeRay(x:Float, y:Float) -> Ray{
        
        let lookAt = -cameraPosition.normalized()
        let eyeVector = (lookAt - cameraPosition).normalized()
        let rightVector = (eyeVector × cameraUp)//.normalized()
        let upVector = (eyeVector × rightVector)//.normalized()
        
        var rayDirection = eyeVector + rightVector * x + upVector * y;
        rayDirection = rayDirection.normalized()
        
        return Ray(origin: cameraPosition, direction: rayDirection)
    }
    
    func setupScene(){
    
        let leftWall:Box = Box(minPoint: Vector3D(x: -1.0, y: 1.0, z: -1.0),
                               maxPoint: Vector3D(x: -1.0, y: -1.0, z: 1.0),
                               normal: Vector3D(x: 1.0, y: 0.0, z: 0.0),
                               color: Color8(a: 255, r: 192, g: 0, b: 0),
                               shininess:1000.0,
                               material:Material.DIFFUSE)
        
        let rightWall:Box = Box(minPoint: Vector3D(x: 1.0, y: 1.0, z: -1.0),
                                maxPoint: Vector3D(x: 1.0, y: -1.0, z: 1.0),
                                normal: Vector3D(x: -1.0, y: 0.0, z: 0.0),
                                color: Color8(a: 255, r: 0, g: 0, b: 192),
                                shininess:1000.0,
                                material:Material.DIFFUSE)
        
        let backWall:Box = Box(minPoint: Vector3D(x: -1.0, y: -1.0, z: -1.0),
                               maxPoint: Vector3D(x: 1.0, y: 1.0, z: -1.0),
                               normal: Vector3D(x: 0.0, y: 0.0, z: 1.0),
                               color: Color8(a: 255, r: 192, g: 192, b: 192),
                               shininess:1000.0,
                               material:Material.DIFFUSE)
        
        let frontWall:Box = Box(minPoint: Vector3D(x: 1.0, y: 1.0, z: 1.0),
                               maxPoint: Vector3D(x: -1.0, y: -1.0, z: 1.0),
                               normal: Vector3D(x: 0.0, y: 0.0, z: -1.0),
                               color: Color8(a: 255, r: 192, g: 192, b: 192),
                               shininess:1000.0,
                               material:Material.DIFFUSE)
        
        let topWall:Box = Box(minPoint: Vector3D(x: 1.0, y: 1.0, z: 1.0),
                                maxPoint: Vector3D(x: -1.0, y: 1.0, z: -1.0),
                                normal: Vector3D(x: 0.0, y: -1.0, z: 0.0),
                                color: Color8(a: 255, r: 192, g: 192, b: 192),
                                shininess:1000.0,
                                material:Material.DIFFUSE)
        
        let bottomWall:Box = Box(minPoint: Vector3D(x: 1.0, y: -1.0, z: 1.0),
                              maxPoint: Vector3D(x: -1.0, y: -1.0, z: -1.0),
                              normal: Vector3D(x: 0.0, y: 1.0, z: 0.0),
                              color: Color8(a: 255, r: 192, g: 192, b: 192),
                              shininess:1000.0,
                              material:Material.DIFFUSE)
        
        sceneObjects =  [leftWall, rightWall, topWall, bottomWall, frontWall, backWall, glassSphere, mirrorSphere, diffuseSphere]
        
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
    
    func reflectRay(origin:Vector3D, normal:Vector3D) -> Ray {
        let cosine = direction ⋅ normal
        return Ray(origin: origin, direction: self.direction - (normal * 2.0 * cosine))
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
        // reflection
        let reflectionProbability:Float = 0.1;
        if(Float(arc4random()) / Float(UINT32_MAX) < reflectance + reflectionProbability) {
            return reflectRay(origin, normal: normal)
        }
        // refraction
        let refractDirection = ((direction + (normal * theta1)) * eta) + (normal * -theta2)
        return Ray(origin: origin, direction: refractDirection)
    }
}

protocol SceneObject{
    var color:Color8 { get set }
    var material:Material { get set }
    var shininess:Float { get set }
    func checkRayIntersection(ray:Ray, inout t:Float, inout normal:Vector3D, inout hitPosition:Vector3D) -> Bool
}

struct Box : SceneObject {
    
    let minPoint:Vector3D
    let maxPoint:Vector3D
    let normal:Vector3D
    var color:Color8
    var shininess: Float
    var material: Material
    
    func checkRayIntersection(ray:Ray, inout t:Float, inout normal:Vector3D, inout hitPosition:Vector3D) -> Bool {
        
        if (normal ⋅ ray.direction > 0){
            return false
        }
        
        let tMin:Vector3D = (minPoint - ray.origin) / ray.direction
        let tMax:Vector3D = (maxPoint - ray.origin) / ray.direction
        let t1:Vector3D = min(tMin, right: tMax)
        let t2:Vector3D = max(tMin, right: tMax)
        let tNear:Float = max(max(t1.x, t1.y), t1.z)
        let tFar:Float = min(min(t2.x, t2.y), t2.z)
        
        
        if (tNear > tFar){
            return false
        }
        
        if (tNear <= 0.001 && tFar <= 0.001){
            return false;
        }
        
        if (tNear <= 0.001) {
            t = tNear;
        } else{
            t = tFar;
        }
        
        normal = self.normal.normalized()
        hitPosition = ray.origin + ray.direction * t
        
        return true
        
    }
}

struct Sphere : SceneObject {
    var center:Vector3D
    let radius:Float
    var color:Color8
    var shininess: Float
    var material: Material
    
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
