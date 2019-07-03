//
//  RasterizationRenderer.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/8/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct Triangle {
    var vertex0: Vertex
    var vertex1: Vertex
    var vertex2: Vertex
}

struct Vertex {
    var point: Vector3D
    var normal: Vector3D
}

func interpolate(min: Vertex, max: Vertex, distance: Float) -> Vertex {
    let returnPoint = interpolate(min: min.point, max: max.point, distance: distance)
    let returnNormal = interpolate(min: min.normal, max: max.normal, distance: distance)
    return Vertex(point: returnPoint, normal: returnNormal)
}

final class RasterizationRenderer: Renderer {

    let lightPosition: Vector3D = Vector3D(x: 1.0, y: 1.0, z: 1.0)
    let cameraPosition: Vector3D = Vector3D(x: 0.0, y: 0.0, z: 5.0)
    var width: Int = 0
    var height: Int = 0
    var currentRotation: Float = 0.0
    var zBuffer: [[Float]] = [[Float]]()
    var output: [[Color]] = [[Color]]()

    lazy var triangles: [Triangle] = {
        guard let filePath = Bundle.main.url(forResource: "teapot", withExtension: "obj") else {
            fatalError("Couldn't Find Teapot")
        }

        return loadObjectFile(filePath: filePath)
    }()

    //Matrices
    var modelMatrix: Matrix = Matrix.identityMatrix()
    var perspectiveMatrix: Matrix = Matrix.identityMatrix()
    var viewMatrix: Matrix = Matrix.identityMatrix()
    var invertedPerspectiveMatrix: Matrix = Matrix.identityMatrix()
    var normalMatrix: Matrix = Matrix.identityMatrix()

    func render(width: Int, height: Int) -> CGImage? {
        self.width = width
        self.height = height

        // Rotate the model
        currentRotation += 0.02

        // Update the math with the new rotation
        updateMatrices()

        // Clear the output array
        clearOutput()

        // Draw each triangle
        triangles.forEach {
            draw(triangle: $0)
        }
        return CGImage.image(colorData: output)
    }

    func clearOutput() {
        output = [[Color]](repeating: [Color](repeating: Color.gray, count: height), count: width)
        zBuffer = [[Float]](repeating: [Float](repeating: Float.greatestFiniteMagnitude, count: height), count: width)
    }

    func loadObjectFile(filePath: URL) -> [Triangle] {
        guard let fileContents = try? String(contentsOf: filePath, encoding: .ascii) else {
            fatalError("Couldn't Load File")
        }

        let lines = fileContents.components(separatedBy: "\n")
        var points = [Vector3D]()
        var normals = [Vector3D]()

        var triangles = [Triangle]()

        for line: String in lines {
            if line.hasPrefix("v ") {
                let values = line.components(separatedBy: " ")
                let point = Vector3D(x: Float(values[1])!, y: Float(values[2])!, z: Float(values[3])!)
                points.append(point)
            }

            if line.hasPrefix("vn ") {
                let values = line.components(separatedBy: " ")
                let normal = Vector3D(x: Float(values[1])!, y: Float(values[2])!, z: Float(values[3])!)
                normals.append(normal)
            }
            if line.hasPrefix("f ") {
                let values: [String] = line.components(separatedBy: " ")
                let pointIndex0  = Int(values[1].components(separatedBy: "//")[0])! - 1
                let normalIndex0 = Int(values[1].components(separatedBy: "//")[1])! - 1

                let pointIndex1  = Int(values[2].components(separatedBy: "//")[0])! - 1
                let normalIndex1 = Int(values[2].components(separatedBy: "//")[1])! - 1

                let pointIndex2  = Int(values[3].components(separatedBy: "//")[0])! - 1
                let normalIndex2 = Int(values[3].components(separatedBy: "//")[1])! - 1

                let vertex0: Vertex = Vertex(point: points[pointIndex0], normal: normals[normalIndex0])
                let vertex1: Vertex = Vertex(point: points[pointIndex1], normal: normals[normalIndex1])
                let vertex2: Vertex = Vertex(point: points[pointIndex2], normal: normals[normalIndex2])

                triangles.append(Triangle(vertex0: vertex0, vertex1: vertex1, vertex2: vertex2))
            }
        }
        return triangles
    }

    func updateMatrices() {
        // The model matrix is the matrix that is responsible for rotating and positioning the model in 3D space
        modelMatrix = Matrix.rotateY(angle: -currentRotation) *
                      Matrix.rotateX(angle: 0.65) *
                      Matrix.translate(vector: Vector3D(x: 0.0, y: -0.4, z: 0.0))

        // The view matrix transforms from 3D space into camera space
        viewMatrix = Matrix.lookAt(origin: cameraPosition, target: Vector3D(x: 0, y: 0, z: 0), cameraUp: Vector3D.up())

        // The perspective matrix adds the illusion of perspective
        perspectiveMatrix = Matrix.perspective(
            fov: 0.78,
            aspectRatio: Float(width)/Float(height),
            zNear: -1.0,
            zFar: 1.0
        )

        // The inverse perspective Matrix, used for lighting calculation
        invertedPerspectiveMatrix = Matrix.inverse(matrix: perspectiveMatrix)

        // The normal matrix, used for lighting
        normalMatrix = Matrix.transpose(matrix: Matrix.inverse(matrix: modelMatrix * viewMatrix))
    }

    func draw(triangle: Triangle) {
        // Define the vertices of the triangle that we will draw
        var vertex0 = triangle.vertex0
        var vertex1 = triangle.vertex1
        var vertex2 = triangle.vertex2

        // Rotate the vertices, transform them into camera space, and then apply perspective calculations
        vertex0.point = vertex0.point * modelMatrix * viewMatrix * perspectiveMatrix
        vertex1.point = vertex1.point * modelMatrix * viewMatrix * perspectiveMatrix
        vertex2.point = vertex2.point * modelMatrix * viewMatrix * perspectiveMatrix

        // Check if the triangle is visible to the camera. If it isn't, don't render it.
        if (vertex0.point - cameraPosition) ⋅ ((vertex1.point - vertex0.point) × (vertex2.point - vertex0.point)) >= 0 {
            return
        }

        // Sort the vertices from top to bottom
        let vertices = [vertex0, vertex1, vertex2].sorted {
            return $0.point.y < $1.point.y
        }

        vertex0 = vertices[0]
        vertex1 = vertices[1]
        vertex2 = vertices[2]

        // Project the three points of the triangle into 2D screen space
        vertex0.point = project(point: vertex0.point)
        vertex1.point = project(point: vertex1.point)
        vertex2.point = project(point: vertex2.point)

        // First, draw the top half of the triangle

        // Calculate the left and right points
        var leftVertex = (vertex2.point.x < vertex1.point.x) ? vertex2 : vertex1
        var rightVertex = (vertex2.point.x < vertex1.point.x) ? vertex1 : vertex2

        for yPos in Int(vertex0.point.y)...Int(vertex1.point.y) {
            // Calculate the distance along the left and right slopes for that row of pixels.
            let leftDistance = (Float(yPos) - vertex0.point.y) / (leftVertex.point.y - vertex0.point.y)
            let rightDistance = (Float(yPos) - vertex0.point.y) / (rightVertex.point.y - vertex0.point.y)

            // Create two points along the edges of triangle using interporlation
            let start = interpolate(min: vertex0, max: leftVertex, distance: leftDistance)
            let end = interpolate(min: vertex0, max: rightVertex, distance: rightDistance)

            // Draw a horizontal line between the two interpolated points
            drawLine(left: start, right: end)
        }

        // We've reached the mid point of the triangle. Draw the bottom half the triangle.

        // Recalculate the left and right point.
        leftVertex = (vertex0.point.x < vertex1.point.x) ? vertex0 : vertex1
        rightVertex = (vertex0.point.x < vertex1.point.x) ? vertex1 : vertex0

        for row in Int(vertex1.point.y)...Int(vertex2.point.y) {
            let leftDistance = (Float(row) - leftVertex.point.y) / (vertex2.point.y - leftVertex.point.y)
            let rightDistance = (Float(row) - rightVertex.point.y) / (vertex2.point.y - rightVertex.point.y)

            let left = interpolate(min: leftVertex, max: vertex2, distance: leftDistance)
            let right = interpolate(min: rightVertex, max: vertex2, distance: rightDistance)

            drawLine(left: left, right: right)
        }
    }

    func drawLine(left: Vertex, right: Vertex) {
        var left = left
        var right = right
        let yPos = Int(left.point.y)

        if left.point.x > right.point.x {
            swap(&left, &right)
        }

        for xPos in Int(left.point.x) ..< Int(right.point.x) {
            let horizontalDistance = (Float(xPos) - left.point.x) / (right.point.x - left.point.x)
            var vertex = interpolate(min: left, max: right, distance: horizontalDistance)

            if xPos >= 0 && yPos >= 0 && xPos < width && yPos < height {
                // Only draw this point to the output if the z is closer to the camera than the last calculated z
                if vertex.point.z < zBuffer[yPos][xPos] {
                    zBuffer[yPos][xPos] = vertex.point.z
                    vertex.point = unproject(point: vertex.point) * invertedPerspectiveMatrix
                    vertex.normal = Matrix.transformPoint(left: normalMatrix, right: vertex.normal).normalized()
                    let color = shade(vertex: vertex)
                    output[yPos][xPos] = color
                }
            }
        }
    }

    func unproject(point: Vector3D) -> Vector3D {
        let projectedX = ((point.x / Float(width)) * 2.0) - 1.0
        let projectedY = ((point.y / Float(height)) * 2.0) - 1.0
        return Vector3D(x: projectedX, y: projectedY, z: point.z)
    }

    func project(point: Vector3D) -> Vector3D {
        let projectedX = point.x * Float(width) + Float(width) / 2.0
        let projectedY = point.y * Float(height) + Float(height) / 2.0
        return Vector3D(x: projectedX, y: projectedY, z: point.z)
    }

    func shade(vertex: Vertex) -> Color {
        let diffuseColor = Color.royalBlue
        let ambientColor = Color.gray
        let lightColor   = Color.white

        return calculatePhongLightingFactor(
            lightPosition: lightPosition,
            targetPosition: vertex.point,
            targetNormal: vertex.normal,
            diffuseColor: diffuseColor,
            ambientColor: ambientColor,
            shininess: 4.0,
            lightColor: lightColor
        )
    }
}
