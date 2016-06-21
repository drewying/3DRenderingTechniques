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

func calculateLightingFactor(lightPosition:Vector3D, targetPosition:Vector3D, targetNormal:Vector3D) -> Float{
    let lightDistance = (lightPosition - targetPosition).length()
    let lightVector = (lightPosition - targetPosition).normalized()
    var lightFactor = max((lightVector ⋅ targetNormal), 0.25)
    lightFactor *= (1.0 / (1.0 + (0.25 * lightDistance * lightDistance)))
    return lightFactor
}