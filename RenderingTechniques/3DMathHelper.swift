//
//  MathHelper.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/20/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

func clamp(_ value: Float) -> Float {
    return max(0.0, min(value, 1.0))
}

func mix(left: Vector3D, right: Vector3D, mixValue: Float) -> Vector3D {
    return left * (1 - mixValue) + right * mixValue
}

func mix(left: Color, right: Color, mixValue: Float) -> Color {
    return left * (1 - mixValue) + right * mixValue
}

func interpolate(min: Float, max: Float, distance: Float) -> Float {
    return min + (max - min) * clamp(distance)
}

func interpolate(min: Vector3D, max: Vector3D, distance: Float) -> Vector3D {
    let interpolatedX = interpolate(min: min.x, max: max.x, distance: distance)
    let interpolatedY = interpolate(min: min.y, max: max.y, distance: distance)
    let interpolatedZ = interpolate(min: min.z, max: max.z, distance: distance)

    return Vector3D(x: interpolatedX, y: interpolatedY, z: interpolatedZ)
}

func interpolate(min: Color, max: Color, distance: Float) -> Color {
    let interpolatedR: Float = interpolate(min: min.red, max: max.red, distance: distance)
    let interpolatedG: Float = interpolate(min: min.green, max: max.green, distance: distance)
    let interpolatedB: Float = interpolate(min: min.blue, max: max.blue, distance: distance)

    return Color(red: interpolatedR, green: interpolatedG, blue: interpolatedB)
}

func calculateLightingFactor(lightPosition: Vector3D, targetPosition: Vector3D, targetNormal: Vector3D) -> Float {
    let lightDistance = (lightPosition - targetPosition).length()
    let lightVector = (lightPosition - targetPosition).normalized()
    var lightFactor = max((lightVector ⋅ targetNormal), 0.25)
    lightFactor *= (1.0 / (1.0 + (0.25 * lightDistance * lightDistance)))
    return lightFactor
}

func calculatePhongLightingFactor(
    targetVertex: Vertex,
    lightPosition: Vector3D,
    lightColor: Color,
    diffuseColor: Color,
    shininess: Float) -> Color {

    let targetNormal = targetVertex.normal
    let targetPosition = targetVertex.point
    var diffuseLightingComponent: Float = 0.0
    var specularLightingCompnent: Float = 0.0

    let lightDirection = (lightPosition - targetPosition).normalized()

    let reflectDirection = (-lightDirection) - 2.0 * (targetNormal ⋅ (-lightDirection)) * targetNormal

    let viewDirection = (-targetPosition).normalized()

    diffuseLightingComponent = max((lightDirection ⋅ targetNormal), 0)

    if diffuseLightingComponent > 0.0 {
        let specularAngle = max((reflectDirection ⋅ viewDirection), 0.0)
        specularLightingCompnent = pow(specularAngle, shininess)
    }

    return diffuseColor * diffuseLightingComponent + lightColor * specularLightingCompnent
}
