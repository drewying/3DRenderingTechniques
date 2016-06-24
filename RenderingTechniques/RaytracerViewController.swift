//
//  RaytracerViewController.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/15/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct ColorF {
    let r:Float
    let g:Float
    let b:Float
}

func * (left: ColorF, right: ColorF) -> ColorF{
    return ColorF(r: left.r * right.r, g: left.g * right.g, b: left.b * right.b)
}

func * (left: ColorF, right: Float) -> ColorF{
    return ColorF(r: left.r * right, g: left.g * right, b: left.b * right)
}

func + (left: ColorF, right: ColorF) -> ColorF{
    return ColorF(r: left.r + right.r, g: left.g + right.g, b: left.b + right.b)
}

class RaytracerViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    
    var timer: CADisplayLink! = nil
    var samplenumber:Int = 0
    let cameraPosition = Vector3D(x: 0.0, y: 0.0, z: -0.9)
    let cameraUp = Vector3D.up()
    let lightPosition = Vector3D(x: 0.0, y: 0.9, z: 0.0)
    var sceneObjects:[SceneObject] = Array<SceneObject>()

    
    @IBOutlet weak var fpsLabel: UILabel!
    
    var colorBuffer:[ColorF] = Array<ColorF>();
    var currentRotation:Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        renderView.clear()
        colorBuffer = Array<ColorF>(count: renderView.width * renderView.height, repeatedValue: ColorF(r: 0.0, g: 0.0, b: 0.0))
        samplenumber = 0
        timer = CADisplayLink(target: self, selector: #selector(RasterizationViewController.renderLoop))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }
    
    func renderLoop() {
        let startTime:NSDate = NSDate()
        drawScreen()
        renderView.render()
        samplenumber += 1
        self.fpsLabel.text = String(format: "%.1 FPS", 1.0 / Float(-startTime.timeIntervalSinceNow))
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
                //var cameraX = -0.5 + Float(x)  * dx * aspectRatio * scale
                //var cameraY = -0.5 + Float(y)  * dy * scale
                let ray:Ray = makeRay(cameraX, y: cameraY)
                
                
                let newColor = traceRay(ray, bounceIteration: 0)
                let currentColor = colorBuffer[y * renderView.width + x]
                let mixedColor = ((currentColor * Float(samplenumber)) + newColor)  *  (1.0/Float(samplenumber + 1)) //interpolate(currentColor, max: newColor, distance: Float(samplenumber) / Float(samplenumber + 1))
                colorBuffer[y * renderView.width + x] = mixedColor
                
                let r:UInt8 = UInt8(min(mixedColor.r * 255.0, 255.0))
                let g:UInt8 = UInt8(min(mixedColor.g * 255.0, 255.0))
                let b:UInt8 = UInt8(min(mixedColor.b * 255.0, 255.0))
                
                
                renderView.plot(x, y: y, color: Color8(a: 255, r: r, g: g, b: b))
            }
        }
    }
    
    func traceRay(ray:Ray, bounceIteration:Int) -> ColorF {

        
        if (bounceIteration > 3){
            return ColorF(r: 0.0, g: 0.0, b: 0.0)
        }
        
        var normal:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 0.0)
        var hitPosition:Vector3D = Vector3D(x: 0.0, y: 0.0, z: 0.0)
        var currentDistance = FLT_MAX
        
        var closestSceneObject:SceneObject = sceneObjects[0]
        var closestHitPosition:Vector3D = hitPosition
        var closestNormal:Vector3D = normal;
        
        for sceneObject in sceneObjects {
            var distance:Float = FLT_MAX
            if (sceneObject.checkRayIntersection(ray, t: &distance, normal: &normal, hitPosition: &hitPosition)){
                if (distance < currentDistance){
                    currentDistance = distance
                    closestSceneObject = sceneObject
                    closestNormal = normal
                    closestHitPosition = hitPosition
                }
            }
        }
        
        var nextRay = ray;
        
        switch closestSceneObject.material {
        case Material.DIFFUSE:
            nextRay = ray.bounceRay(closestHitPosition, normal: closestNormal)
            break
        case Material.REFLECTIVE:
            nextRay = ray.reflectRay(closestHitPosition, normal: closestNormal)
            break
        case Material.REFRACTIVE:
            nextRay = ray.refractRay(closestHitPosition, normal: closestNormal)
            break
        }
    
        return traceRay(nextRay, bounceIteration: bounceIteration + 1) * closestSceneObject.color + closestSceneObject.emission
    }
    
    func calculateLightingFactor(lightPosition:Vector3D, targetPosition:Vector3D, targetNormal:Vector3D, diffuseColor:ColorF, ambientColor:ColorF, shininess:Float, lightColor:ColorF) -> ColorF{
        
        var diffuseLightingComponent:Float = 0.0
        var specularLightingCompnent:Float = 0.0
        
        let lightDirection = (lightPosition - targetPosition).normalized()
        
        let reflectDirection = (-lightDirection) - 2.0 * (targetNormal ⋅ (-lightDirection)) * targetNormal
        
        
        let viewDirection = (-targetPosition).normalized()
        
        diffuseLightingComponent = max((lightDirection ⋅ targetNormal), 0)
        
        if (diffuseLightingComponent > 0.0){
            let specularAngle = max((reflectDirection ⋅ viewDirection), 0.0)
            specularLightingCompnent = pow(specularAngle, shininess)
        }
        
        return diffuseColor * diffuseLightingComponent + lightColor * specularLightingCompnent
        
    }
    
    func makeRay(x:Float, y:Float) -> Ray{
        
        let lookAt = -cameraPosition.normalized()
        let eyeVector = (lookAt - cameraPosition).normalized()
        let rightVector = (eyeVector × cameraUp)
        let upVector = (eyeVector × rightVector)
        
        var rayDirection = eyeVector + rightVector * x + upVector * y;
        rayDirection = rayDirection.normalized()
        
        return Ray(origin: cameraPosition, direction: rayDirection)
    }
    
    func setupScene(){
        let leftWall:Box = Box(minPoint: Vector3D(x: -1.0, y: 1.0, z: -1.0),
                               maxPoint: Vector3D(x: -1.0, y: -1.0, z: 1.0),
                               normal: Vector3D(x: 1.0, y: 0.0, z: 0.0),
                               color: ColorF(r: 0.75, g: 0, b: 0),
                               emission: ColorF(r: 0.0, g: 0.0, b: 0.0),
                               shininess:100.0,
                               material:Material.DIFFUSE)
        
        let rightWall:Box = Box(minPoint: Vector3D(x: 1.0, y: 1.0, z: -1.0),
                                maxPoint: Vector3D(x: 1.0, y: -1.0, z: 1.0),
                                normal: Vector3D(x: -1.0, y: 0.0, z: 0.0),
                                color: ColorF(r: 0, g: 0, b: 0.75),
                                emission: ColorF(r: 0.0, g: 0.0, b: 0.0),
                                shininess:100.0,
                                material:Material.DIFFUSE)
        
        let backWall:Box = Box(minPoint: Vector3D(x: -1.0, y: -1.0, z: -1.0),
                               maxPoint: Vector3D(x: 1.0, y: 1.0, z: -1.0),
                               normal: Vector3D(x: 0.0, y: 0.0, z: 1.0),
                               color: ColorF(r: 0.75, g: 0.75, b: 0.75),
                               emission: ColorF(r: 0.0, g: 0.0, b: 0.0),
                               shininess:100.0,
                               material:Material.DIFFUSE)
        
        let frontWall:Box = Box(minPoint: Vector3D(x: 1.0, y: 1.0, z: 1.0),
                               maxPoint: Vector3D(x: -1.0, y: -1.0, z: 1.0),
                               normal: Vector3D(x: 0.0, y: 0.0, z: -1.0),
                               color: ColorF(r: 0.75, g: 0.75, b: 0.75),
                               emission: ColorF(r: 0.0, g: 0.0, b: 0.0),
                               shininess:100.0,
                               material:Material.DIFFUSE)
        
        let topWall:Box = Box(minPoint: Vector3D(x: 1.0, y: 1.0, z: 1.0),
                                maxPoint: Vector3D(x: -1.0, y: 1.0, z: -1.0),
                                normal: Vector3D(x: 0.0, y: -1.0, z: 0.0),
                                color: ColorF(r: 0.0, g: 0.0, b: 0.0),
                                emission: ColorF(r: 1.6, g: 1.47, b: 1.29),
                                shininess:100.0,
                                material:Material.DIFFUSE)
        
        let bottomWall:Box = Box(minPoint: Vector3D(x: 1.0, y: -1.0, z: 1.0),
                              maxPoint: Vector3D(x: -1.0, y: -1.0, z: -1.0),
                              normal: Vector3D(x: 0.0, y: 1.0, z: 0.0),
                              color: ColorF(r: 0.75, g: 0.75, b: 0.75),
                              emission: ColorF(r: 0.0, g: 0.0, b: 0.0),
                              shininess:100.0,
                              material:Material.DIFFUSE)
        
        let mirrorSphere:Sphere = Sphere(center: Vector3D(x: -0.5, y: -0.7, z: 0.7), radius: 0.3, color: ColorF(r: 1.0, g: 1.0, b: 1.0), emission: ColorF(r: 0.0, g: 0.0, b: 0.0), shininess:100.0, material:Material.REFLECTIVE )
        let glassSphere:Sphere = Sphere(center: Vector3D(x: 0.5, y: -0.7, z: 0.3), radius: 0.3, color: ColorF(r: 1.0, g: 1.0, b: 1.0), emission: ColorF(r: 0.0, g: 0.0, b: 0.0), shininess:100.0, material:Material.REFRACTIVE )
        
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
        let theta:Float = 2 * Float(M_PI) * u2;
        
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
        // reflection
        let reflectionProbability:Float = 0.1;
        if(Float(arc4random()) / Float(UINT32_MAX) < reflectance + reflectionProbability) {
            return reflectRay(origin, normal: normal)
        }
        // refraction
        let refractDirection = ((direction + (normal * theta1)) * eta) + (normal * -theta2)
        return Ray(origin: origin, direction: refractDirection.normalized())
    }
}

protocol SceneObject{
    var emission:ColorF {get set}
    var color:ColorF { get set }
    var material:Material { get set }
    var shininess:Float { get set }
    func checkRayIntersection(ray:Ray, inout t:Float, inout normal:Vector3D, inout hitPosition:Vector3D) -> Bool
}

struct HitRecord {
    let hitPosition:Vector3D
    let hitNormal:Vector3D
    let hitDistance:Float
}

struct Box : SceneObject {
    
    let minPoint:Vector3D
    let maxPoint:Vector3D
    let normal:Vector3D
    var color:ColorF
    var emission: ColorF
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
    var color:ColorF
    var emission: ColorF
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
