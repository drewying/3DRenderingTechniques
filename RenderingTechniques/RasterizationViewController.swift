//
//  RasterizationViewController.swift
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

class RasterizationViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    @IBOutlet weak var fpsLabel: UILabel!
    var timer: CADisplayLink! = nil

    let lightPosition: Vector3D = Vector3D(x: 1.0, y: 1.0, z: 1.0)
    let cameraPosition: Vector3D = Vector3D(x: 0.0, y: 0.0, z: 5.0)

    var currentRotation: Float = 0.0
    var triangles: [Triangle] = [Triangle]()
    var zBuffer: [[Float]] = [[Float]]()

    //Matrices
    var modelMatrix: Matrix = Matrix.identityMatrix()
    var perspectiveMatrix: Matrix = Matrix.identityMatrix()
    var viewMatrix: Matrix = Matrix.identityMatrix()
    var invertedPerspectiveMatrix: Matrix = Matrix.identityMatrix()
    var normalMatrix: Matrix = Matrix.identityMatrix()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadTeapot()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer = CADisplayLink(target: self, selector: #selector(renderLoop))
        timer.add(to: .current, forMode: .common)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }

    @objc func renderLoop() {
        let startTime: NSDate = NSDate()
        updateMatrices()
        zBuffer = [[Float]](repeating: [Float](repeating: Float.greatestFiniteMagnitude, count: renderView.height), count: renderView.width)
        renderView.clear()
        triangles.forEach {
            render(triangle: $0)
        }
        renderView.render()
        currentRotation += 0.02
        self.fpsLabel.text = String(format: "%.1 FPS", 1.0 / Float(-startTime.timeIntervalSinceNow))

    }

    func loadTeapot() {
        guard let filepath = Bundle.main.url(forResource: "teapot", withExtension: "obj") else {
            fatalError("Couldn't Load Teapot")
        }

        do {
            let contents: String = try String(contentsOf: filepath, encoding: .ascii)
            let lines = contents.components(separatedBy: "\n")
            var points = [Vector3D]()
            var normals = [Vector3D]()

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
        } catch {
            print("Couldn't load teapot")
        }
    }

    func updateMatrices() {
        //The model matrix is the matrix that iss responsible for positioning the model in world space
        modelMatrix = Matrix.rotateY(angle: -currentRotation) *
                      Matrix.rotateX(angle: 0.65) *
                      Matrix.translate(vector: Vector3D(x: 0.0, y: -0.4, z: 0.0))

        //The view matrix transforms from world space into camera space
        viewMatrix = Matrix.lookAt(origin: cameraPosition, target: Vector3D(x: 0, y: 0, z: 0), cameraUp: Vector3D.up())
        //The perspective matrix adds the illusion of perspective
        perspectiveMatrix = Matrix.perspective(fov: 0.78, aspectRatio: Float(renderView.width)/Float(renderView.height), zNear: -1.0, zFar: 1.0)
        //The inverse perspective, used for lighting
        invertedPerspectiveMatrix = Matrix.inverse(matrix: perspectiveMatrix)
        //The normal matrix, used for lighting
        normalMatrix = Matrix.transpose(matrix: Matrix.inverse(matrix: modelMatrix * viewMatrix))

    }

    func render(triangle: Triangle) {

        var vertex0 = triangle.vertex0
        var vertex1 = triangle.vertex1
        var vertex2 = triangle.vertex2

        //Transform the vertices of the triangle.
        vertex0.point = vertex0.point * modelMatrix * viewMatrix * perspectiveMatrix
        vertex1.point = vertex1.point * modelMatrix * viewMatrix * perspectiveMatrix
        vertex2.point = vertex2.point * modelMatrix * viewMatrix * perspectiveMatrix

        //Check if the triangle is visible to the camera. If not, don't render it.
        if (vertex0.point - cameraPosition) ⋅ ((vertex1.point - vertex0.point) × (vertex2.point - vertex0.point)) >= 0 {
            return
        }

        //Sort the Vertices from top to bottom
        let vertices: [Vertex] = [vertex0, vertex1, vertex2].sorted {
            return $0.point.y < $1.point.y
        }

        vertex0 = vertices[0]
        vertex1 = vertices[1]
        vertex2 = vertices[2]

        //Project the three points of the triangle into screen space, and add transform the points for perspective.
        //This fulfills the role of the typical vertext shader.
        vertex0.point = project(point: vertex0.point)
        vertex1.point = project(point: vertex1.point)
        vertex2.point = project(point: vertex2.point)

        //Plot the top half of the triangle.
        //Calculate the and right points.
        var leftVertex = (vertex2.point.x < vertex1.point.x) ? vertex2 : vertex1
        var rightVertex = (vertex2.point.x < vertex1.point.x) ? vertex1 : vertex2

        for row in Int(vertex0.point.y)...Int(vertex1.point.y) {
            //Calculate the distance along the left and right slopes for that row of pixels.
            let leftDistance = (Float(row) - vertex0.point.y) / (leftVertex.point.y - vertex0.point.y)
            let rightDistance = (Float(row) - vertex0.point.y) / (rightVertex.point.y - vertex0.point.y)

            //Create two points along the edges of triangle through interporlation
            let start = interpolate(min: vertex0, max: leftVertex, distance: leftDistance)
            let end = interpolate(min: vertex0, max: rightVertex, distance: rightDistance)

            //Plot a horizontal line
            plotScanLine(row: row, left: start, right: end)
        }

        //Plot the bottom half the triangle.

        //We've reached the mid point. Recalculate the left and right point.
        leftVertex = (vertex0.point.x < vertex1.point.x) ? vertex0 : vertex1
        rightVertex = (vertex0.point.x < vertex1.point.x) ? vertex1 : vertex0

        for row in Int(vertex1.point.y)...Int(vertex2.point.y) {
            let leftDistance = (Float(row) - leftVertex.point.y) / (vertex2.point.y - leftVertex.point.y)
            let rightDistance = (Float(row) - rightVertex.point.y) / (vertex2.point.y - rightVertex.point.y)

            let start = interpolate(min: leftVertex, max: vertex2, distance: leftDistance)
            let end = interpolate(min: rightVertex, max: vertex2, distance: rightDistance)

            plotScanLine(row: row, left: start, right: end)
        }
    }

    func plotScanLine(row: Int, left: Vertex, right: Vertex) {

        var start = left
        var end = right

        if left.point.x > right.point.x {
            swap(&start, &end)
        }

        for col in Int(start.point.x) ..< Int(end.point.x) {
            let horizontalDistance = (Float(col) - start.point.x) / (end.point.x - start.point.x)
            var vertex = interpolate(min: start, max: end, distance: horizontalDistance)

            if col >= 0 && row >= 0 && col < renderView.width && row < renderView.height {
                if vertex.point.z < zBuffer[col][row] {
                    zBuffer[col][row] = vertex.point.z
                    vertex.point = unproject(point: vertex.point) * invertedPerspectiveMatrix
                    vertex.normal = Matrix.transformPoint(left: normalMatrix, right: vertex.normal).normalized()
                    let color = shader(vertex: vertex)
                    renderView.plot(x: col, y: row, color: color)
                }
            }
        }
    }

    func unproject(point: Vector3D) -> Vector3D {
        let projectedX = ((point.x / Float(renderView.width)) * 2.0) - 1.0
        let projectedY = ((point.y / Float(renderView.height)) * 2.0) - 1.0
        return Vector3D(x: projectedX, y: projectedY, z: point.z)
    }

    func project(point: Vector3D) -> Vector3D {
        let projectedX = point.x * Float(renderView.width) + Float(renderView.width) / 2.0
        let projectedY = point.y * Float(renderView.height) + Float(renderView.height) / 2.0
        return Vector3D(x: projectedX, y: projectedY, z: point.z)
    }

    func shader(vertex: Vertex) -> Color {
        let diffuseColor: Color = Color(r: 0.5, g: 0, b: 0)
        let ambientColor: Color = Color(r: 0.33, g: 0.33, b: 0.33)
        let lightColor: Color = Color(r: 1.0, g: 1.0, b: 1.0)
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
