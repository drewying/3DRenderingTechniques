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

func mix(left:Vector3D, right:Vector3D, mixValue:Float) -> Vector3D{
    return left * (1 - mixValue) + right * mixValue
}

func mix(left:Color, right:Color, mixValue:Float) -> Color{
    return left * (1 - mixValue) + right * mixValue
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

func interpolate(min:Color, max:Color, distance:Float) -> Color{
    let r:Float = interpolate(min.r, max: max.r, distance: distance)
    let g:Float = interpolate(min.g, max: max.g, distance: distance)
    let b:Float = interpolate(min.b, max: max.b, distance: distance)
    
    return Color(r: r, g: g, b: b)
}

func calculateLightingFactor(lightPosition:Vector3D, targetPosition:Vector3D, targetNormal:Vector3D) -> Float{
    let lightDistance = (lightPosition - targetPosition).length()
    let lightVector = (lightPosition - targetPosition).normalized()
    var lightFactor = max((lightVector ⋅ targetNormal), 0.25)
    lightFactor *= (1.0 / (1.0 + (0.25 * lightDistance * lightDistance)))
    return lightFactor
}

func calculatePhongLightingFactor(lightPosition:Vector3D, targetPosition:Vector3D, targetNormal:Vector3D, diffuseColor:Color, ambientColor:Color, shininess:Float, lightColor:Color) -> Color{
    
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