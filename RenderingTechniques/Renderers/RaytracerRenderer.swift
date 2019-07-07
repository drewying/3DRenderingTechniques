//
//  RaytracerRenderer.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/15/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import CoreGraphics

// swiftlint:disable variable_name

struct Ray {
    let origin: Vector3D
    let direction: Vector3D

    func bounceRay(from: Vector3D, normal: Vector3D) -> Ray {
        let u1 = Float.random(in: 0...1.0)
        let u2 = Float.random(in: 0...1.0)

        let uu = (normal × Vector3D(x: 0.0, y: 1.0, z: 1.0)).normalized()
        let vv = uu × normal

        let r = sqrt(u1)
        let theta = 2 * .pi * u2

        let x = r * cos(theta)
        let y = r * sin(theta)
        let z = sqrt(1.0 - u1)

        let bounceDirection = x * uu + y * vv + z * normal
        return Ray(origin: from, direction: bounceDirection.normalized() )

    }

    func reflectRay(from: Vector3D, normal: Vector3D) -> Ray {
        let cosine = direction ⋅ normal
        let reflectDirection = direction - (normal * 2.0 * cosine)
        return Ray(origin: from, direction: reflectDirection.normalized())
    }

    func refractRay(from: Vector3D, normal: Vector3D) -> Ray {
        let theta1: Float = abs(direction ⋅ normal)

        var internalIndex: Float = 1.0
        var externalIndex: Float  = 1.5

        if theta1 >= 0.0 {
            internalIndex = 1.5
            externalIndex = 1.0
        }

        let eta: Float = externalIndex/internalIndex
        let theta2: Float = sqrt(1.0 - (eta * eta) * (1.0 - (theta1 * theta1)))
        let rs: Float =
            (externalIndex * theta1 - internalIndex * theta2) /
            (externalIndex * theta1 + internalIndex * theta2)
        let rp: Float =
            (internalIndex * theta1 - externalIndex * theta2) /
            (internalIndex * theta1 + externalIndex * theta2)
        let reflectance: Float = (rs*rs + rp*rp)

        // Check for perfect refraction (Reflection)
        if Float.random(in: 0...1.0) < reflectance {
            return reflectRay(from: origin, normal: normal)
        }

        let refractDirection = ((direction + (normal * theta1)) * eta) + (normal * -theta2)
        return Ray(origin: from, direction: refractDirection.normalized())
    }
}

struct HitRecord {
    let position: Vector3D
    let normal: Vector3D
    let distance: Float
    let object: Sphere
}

struct Sphere {
    enum Material {
        case DIFFUSE
        case REFLECTIVE
        case REFRACTIVE
    }

    var center: Vector3D
    let radius: Float
    var color: Color
    var emission: Color
    var material: Material

    func checkRayIntersection(ray: Ray) -> HitRecord? {
        let v: Vector3D = center - ray.origin
        let b: Float = v ⋅ ray.direction
        let discriminant: Float = b * b - (v ⋅ v) + radius * radius

        if discriminant < 0 {
            return nil
        }

        let d: Float = sqrt(discriminant)
        let tFar: Float = b + d
        let tNear: Float = b - d

        if tFar <= 0.001 && tNear <= 0.001 {
            return nil
        }

        let hitDistance = tNear <= 0.001 ? tFar : tNear
        let hitPosition = ray.origin + ray.direction * hitDistance
        let hitNormal = (hitPosition - center).normalized()

        return HitRecord(position: hitPosition, normal: hitNormal, distance: hitDistance, object: self)
    }
}
// swiftlint:enable variable_name

final class RaytracerRenderer: Renderer {
    var sampleNumber: Int = 0
    let cameraPosition = Vector3D(x: 0.0, y: 0.0, z: -3.0)
    let cameraUp = Vector3D.up()
    let lightPosition = Vector3D(x: 0.0, y: 0.9, z: 0.0)
    lazy var sceneObjects: [Sphere] = {
        return setupScene()
    }()

    var output: [[Color]] = [[Color]]()

    var width: Int = 0
    var height: Int = 0

    func render(width: Int, height: Int) -> CGImage? {
        self.width = width
        self.height = height

        if output.count != width && output.first?.count != height {
            output = [[Color]](repeating: [Color](repeating: Color.black, count: height), count: width)
        }

        for xPos in 0..<width {
            for yPos in 0..<height {
                // Generate a ray that passes through the pixel at (x, y)
                let ray: Ray = makeRayThatIntersectsPixel(xPos: xPos, yPos: yPos)

                // Recursively trace that ray and determine the color
                let newColor = traceRay(ray: ray, bounceIteration: 0)

                // Mix the new color with the current known color.
                let currentColor = output[yPos][xPos]
                let mixedColor = ((currentColor * Float(sampleNumber)) + newColor)  *  (1.0/Float(sampleNumber + 1))
                output[yPos][xPos] = mixedColor
            }
        }
        sampleNumber += 1
        return CGImage.image(colorData: output)
    }

    func traceRay(ray: Ray, bounceIteration: Int) -> Color {

        // We've bounced the ray around the scene 5 times. Return.
        if bounceIteration >= 5 {
            return Color.black
        }

        // Go through each object in the scene and find the closest sphere that the ray intersects with.
        var closestHit: HitRecord?

        for sceneObject: Sphere in sceneObjects {
            if let hitRecord = sceneObject.checkRayIntersection(ray: ray) {
                if hitRecord.distance < closestHit?.distance ?? Float.greatestFiniteMagnitude {
                    closestHit = hitRecord
                }
            }
        }

        guard let hit = closestHit else {
            return Color.black
        }

        // Create a new ray from where we hit to gather more information about the scene
        var nextRay = ray
        switch hit.object.material {
        case .DIFFUSE:
            nextRay = ray.bounceRay(from: hit.position, normal: hit.normal)
        case .REFLECTIVE:
            nextRay = ray.reflectRay(from: hit.position, normal: hit.normal)
        case .REFRACTIVE:
            nextRay = ray.refractRay(from: hit.position, normal: hit.normal)
        }

        // Recursively Gather color and lighting data about the next ray and combine it with this one
        return (traceRay(ray: nextRay, bounceIteration: bounceIteration + 1) * hit.object.color) + hit.object.emission
    }

    func makeRayThatIntersectsPixel(xPos: Int, yPos: Int) -> Ray {
        // Convert pixel coordinates to world coordinate
        let fieldOfView: Float = 0.785 // 45 degrees
        let scale: Float = tanf(fieldOfView * 0.5)
        let aspectRatio = Float(width)/Float(height)
        let dxPos = 1.0 / Float(width)
        let dyPos = 1.0 / Float(height)

        var cameraX = (2 * (Float(xPos) + 0.5) * dxPos - 1) * aspectRatio * scale
        var cameraY = (1 - 2 * (Float(yPos) + 0.5) * dyPos) * scale * -1

        // Randomly move the ray slightly up or down randomly to create anti-aliasing
        let randomX = Float.random(in: 0...1.0)
        let randomY = Float.random(in: 0...1.0)
        cameraX += (randomX - 0.5)/Float(width)
        cameraY += (randomY - 0.5)/Float(height)

        // Transform the world coordinate into a ray
        let lookAt = -cameraPosition.normalized()
        let eyeVector = (lookAt - cameraPosition).normalized()
        let rightVector = (eyeVector × cameraUp)
        let upVector = (eyeVector × rightVector)
        let rayDirection = (eyeVector + rightVector * cameraX + upVector * cameraY).normalized()

        return Ray(origin: cameraPosition, direction: rayDirection)
    }

    func setupScene() -> [Sphere] {
        let leftWall = Sphere(center: Vector3D(x: -10e3, y: 0.0, z: 0.0),
                              radius: 10e3 - 1.0,
                              color: Color.crimson,
                              emission: Color.black,
                              material: .DIFFUSE )

        let rightWall = Sphere(center: Vector3D(x: 10e3, y: 0.0, z: 0.0),
                               radius: 10e3 - 1.0,
                               color: Color.royalBlue,
                               emission: Color.black,
                               material: .DIFFUSE )

        let frontWall = Sphere(center: Vector3D(x: 0.0, y: 0.0, z: 10e3),
                               radius: 10e3 - 2.0,
                               color: Color.offWhite,
                               emission: Color.black,
                               material: .DIFFUSE )

        let backWall = Sphere(center: Vector3D(x: 0.0, y: 0.0, z: -10e3),
                              radius: 10e3 - 3.0,
                              color: Color.offWhite,
                              emission: Color.black,
                              material: .DIFFUSE )

        let topWall = Sphere(center: Vector3D(x: 0.0, y: 10e3, z: 0.0),
                             radius: 10e3 - 1.0,
                             color: Color.black,
                             emission: Color(red: 1.6, green: 1.47, blue: 1.29),
                             material: .DIFFUSE )

        let bottomWall = Sphere(center: Vector3D(x: 0.0, y: -10e3, z: 0.0),
                                radius: 10e3 - 1.0,
                                color: Color.offWhite,
                                emission: Color.black,
                                material: .DIFFUSE )

        let mirrorSphere = Sphere(center: Vector3D(x: -0.5, y: -0.7, z: 0.7),
                                  radius: 0.3,
                                  color: Color.white,
                                  emission: Color.black,
                                  material: .REFLECTIVE )

        let glassSphere = Sphere(center: Vector3D(x: 0.5, y: -0.65, z: 0.25),
                                 radius: 0.35,
                                 color: Color.white,
                                 emission: Color.black,
                                 material: .REFRACTIVE )

        return [leftWall, rightWall, topWall, bottomWall, frontWall, backWall, glassSphere, mirrorSphere]
    }
}
