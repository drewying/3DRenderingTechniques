//
//  File.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/20/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import Foundation

func clamp(value:Float) -> Float{
    return max(0.0, min(value, 1.0));
}

func interpolate(min:Float, max:Float, distance:Float) -> Float{
    return min + (max - min) * clamp(distance);
}

func interpolate(min:Vector3D, max:Vector3D, distance:Float) -> Vector3D{
    let x:Float = interpolate(min.x, max: max.x, distance: distance)
    let y:Float = interpolate(min.y, max: max.y, distance: distance)
    let z:Float = interpolate(min.z, max: max.z, distance: distance)
    
    return Vector3D(x: x, y: y, z: z)
}

func interpolate(min:Color8, max:Color8, distance:Float) -> Color8{
    let r:Float = interpolate(Float(min.r), max: Float(max.r), distance: distance)
    let g:Float = interpolate(Float(min.g), max: Float(max.g), distance: distance)
    let b:Float = interpolate(Float(min.b), max: Float(max.b), distance: distance)
    
    return Color8(a: 255, r: UInt8(r), g: UInt8(g), b: UInt8(b))
}

func calculateLightingFactor(lightPosition:Vector3D, targetPosition:Vector3D, targetNormal:Vector3D) -> Float{
    let lightDistance = (lightPosition - targetPosition).length()
    let lightVector = (lightPosition - targetPosition).normalized()
    var lightFactor = max((lightVector ⋅ targetNormal), 0.25)
    lightFactor *= (1.0 / (1.0 + (0.25 * lightDistance * lightDistance)))
    return lightFactor
}

func calculatePhongLightingFactor(lightPosition:Vector3D, targetPosition:Vector3D, targetNormal:Vector3D, diffuseColor:Color8, ambientColor:Color8, shininess:Float, lightColor:Color8) -> Color8{
    
    var diffuseLightingComponent:Float = 0.0
    var specularLightingCompnent:Float = 0.0
    
    let lightDirection = (lightPosition - targetPosition).normalized()
    diffuseLightingComponent = max((lightDirection ⋅ targetNormal), 0)
    
    if (diffuseLightingComponent > 0.0){
        let viewDirection = (-targetPosition).normalized()
        let halfDirection = (lightDirection + viewDirection).normalized()
        let specularAngle:Float = max((halfDirection ⋅ targetNormal), 0.0)
        specularLightingCompnent = pow(specularAngle, shininess)
    }
    
    return diffuseColor * diffuseLightingComponent + lightColor * specularLightingCompnent
    
}