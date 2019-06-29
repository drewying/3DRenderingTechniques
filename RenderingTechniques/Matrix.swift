//
//  Matrix.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/20/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import UIKit

//This matrix assumes a LH coordinate system

struct Matrix {
    var data: [Float] = [
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0
    ]

    static func identityMatrix() -> Matrix {
        var matrix = Matrix()
        matrix.data = [
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        ]
        return matrix
    }

    static func zeroMatrix() -> Matrix {
        var matrix = Matrix()
        matrix.data = [
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0
        ]
        return matrix
    }

    static func perspective(fov: Float, aspectRatio: Float, zNear: Float, zFar: Float) -> Matrix {
        var result = zeroMatrix()
        let tan = 1.0/tanf(fov * 0.5)
        result.data[0] = tan/aspectRatio
        result.data[5] = tan
        result.data[10] = -zFar / (zNear - zFar)
        result.data[11] = 1.0
        result.data[14] = (zNear * zFar) / (zNear - zFar)

        return result
    }

    static func lookAt(origin: Vector3D, target: Vector3D, cameraUp: Vector3D) -> Matrix {
        let zAxis = (origin - target).normalized()
        let xAxis = (cameraUp × zAxis).normalized()
        let yAxis = zAxis × xAxis

        let xVector = -(xAxis ⋅ origin)
        let yVector = -(yAxis ⋅ origin)
        let zVector = -(zAxis ⋅ origin)

        var result: Matrix = Matrix()
        result.data = [
            xAxis.x, yAxis.x, zAxis.x, 0.0,
            xAxis.y, yAxis.y, zAxis.y, 0.0,
            xAxis.z, yAxis.z, zAxis.z, 0.0,
            xVector, yVector, zVector, 1.0
        ]
        return result
    }

    static func scale(vector: Vector3D) -> Matrix {
        var result = zeroMatrix()
        result.data[0] = vector.x
        result.data[5] = vector.y
        result.data[10] = vector.z
        result.data[15] = 1.0
        return result
    }

    static func translate(vector: Vector3D) -> Matrix {
        var result = identityMatrix()
        result.data[12] = vector.x
        result.data[13] = vector.y
        result.data[14] = vector.z
        return result
    }

    static func rotateX(angle: Float) -> Matrix {
        let cosine: Float = cos(angle)
        let sine: Float = sin(angle)

        var result = zeroMatrix()
        result.data[0] = 1.0
        result.data[15] = 1.0
        result.data[5] = cosine
        result.data[10] = cosine
        result.data[9] = -sine
        result.data[6] = sine

        return result
    }

    static func rotateY(angle: Float) -> Matrix {
        let cosine: Float = cos(angle)
        let sine: Float = sin(angle)

        var result = zeroMatrix()
        result.data[5] = 1.0
        result.data[15] = 1.0
        result.data[0] = cosine
        result.data[2] = -sine
        result.data[8] = sine
        result.data[10] = cosine

        return result
    }

    static func rotateZ(angle: Float) -> Matrix {
        let cosine: Float = cos(angle)
        let sine: Float = sin(angle)

        var result = zeroMatrix()
        result.data[10] = 1.0
        result.data[15] = 1.0
        result.data[0] = cosine
        result.data[1] = sine
        result.data[4] = -sine
        result.data[5] = cosine

        return result
    }

    static func transformVector(left: Matrix, right: Vector3D) -> Vector3D {
        let newX: Float = right.x * left.data[0] + right.y * left.data[4] + right.z * left.data[6] + left.data[8]
        let newY: Float = right.x * left.data[1] + right.y * left.data[5] + right.z * left.data[7] + left.data[9]
        let newZ: Float = right.x * left.data[2] + right.y * left.data[6] + right.z * left.data[8] + left.data[10]
        return Vector3D(x: newX, y: newY, z: newZ)
    }

    static func transformPoint(left: Matrix, right: Vector3D) -> Vector3D {

        let newX: Float = right.x * left.data[0] + right.y * left.data[4] + right.z * left.data[8] + left.data[12]
        let newY: Float = right.x * left.data[1] + right.y * left.data[5] + right.z * left.data[9] + left.data[13]
        let newZ: Float = right.x * left.data[2] + right.y * left.data[6] + right.z * left.data[10] + left.data[14]
        let newW: Float = right.x * left.data[3] + right.y * left.data[7] + right.z * left.data[11] + left.data[15]
        return Vector3D(x: newX/newW, y: newY/newW, z: newZ/newW)
    }

    static func transpose(matrix: Matrix) -> Matrix {
        var result: Matrix = Matrix()
        result.data[0] = matrix.data[0]
        result.data[1] = matrix.data[4]
        result.data[2] = matrix.data[8]
        result.data[3] = matrix.data[12]
        result.data[4] = matrix.data[1]
        result.data[5] = matrix.data[5]
        result.data[6] = matrix.data[9]
        result.data[7] = matrix.data[13]
        result.data[8] = matrix.data[2]
        result.data[9] = matrix.data[6]
        result.data[10] = matrix.data[10]
        result.data[11] = matrix.data[14]
        result.data[12] = matrix.data[3]
        result.data[13] = matrix.data[7]
        result.data[14] = matrix.data[11]
        result.data[15] = matrix.data[15]
        return result
    }

    static func inverse(matrix: Matrix) -> Matrix {
        var result: Matrix = Matrix()
        let l01 = matrix.data[0]
        let l02 = matrix.data[1]
        let l03 = matrix.data[2]
        let l04 = matrix.data[3]
        let l05 = matrix.data[4]
        let l06 = matrix.data[5]
        let l07 = matrix.data[6]
        let l08 = matrix.data[7]
        let l09 = matrix.data[8]
        let l10 = matrix.data[9]
        let l11 = matrix.data[10]
        let l12 = matrix.data[11]
        let l13 = matrix.data[12]
        let l14 = matrix.data[13]
        let l15 = matrix.data[14]
        let l16 = matrix.data[15]
        let l17 = (l11 * l16) - (l12 * l15)
        let l18 = (l10 * l16) - (l12 * l14)
        let l19 = (l10 * l15) - (l11 * l14)
        let l20 = (l09 * l16) - (l12 * l13)
        let l21 = (l09 * l15) - (l11 * l13)
        let l22 = (l09 * l14) - (l10 * l13)
        let l23 = ((l06 * l17) - (l07 * l18)) + (l08 * l19)
        let l24 = -(((l05 * l17) - (l07 * l20)) + (l08 * l21))
        let l25 = ((l05 * l18) - (l06 * l20)) + (l08 * l22)
        let l26 = -(((l05 * l19) - (l06 * l21)) + (l07 * l22))
        let l27 = 1.0 / ((((l01 * l23) + (l02 * l24)) + (l03 * l25)) + (l04 * l26))
        let l28 = (l07 * l16) - (l08 * l15)
        let l29 = (l06 * l16) - (l08 * l14)
        let l30 = (l06 * l15) - (l07 * l14)
        let l31 = (l05 * l16) - (l08 * l13)
        let l32 = (l05 * l15) - (l07 * l13)
        let l33 = (l05 * l14) - (l06 * l13)
        let l34 = (l07 * l12) - (l08 * l11)
        let l35 = (l06 * l12) - (l08 * l10)
        let l36 = (l06 * l11) - (l07 * l10)
        let l37 = (l05 * l12) - (l08 * l09)
        let l38 = (l05 * l11) - (l07 * l09)
        let l39 = (l05 * l10) - (l06 * l09)
        result.data[0] = l23 * l27
        result.data[4] = l24 * l27
        result.data[8] = l25 * l27
        result.data[12] = l26 * l27
        result.data[1] = -(((l02 * l17) - (l03 * l18)) + (l04 * l19)) * l27
        result.data[5] = (((l01 * l17) - (l03 * l20)) + (l04 * l21)) * l27
        result.data[9] = -(((l01 * l18) - (l02 * l20)) + (l04 * l22)) * l27
        result.data[13] = (((l01 * l19) - (l02 * l21)) + (l03 * l22)) * l27
        result.data[2] = (((l02 * l28) - (l03 * l29)) + (l04 * l30)) * l27
        result.data[6] = -(((l01 * l28) - (l03 * l31)) + (l04 * l32)) * l27
        result.data[10] = (((l01 * l29) - (l02 * l31)) + (l04 * l33)) * l27
        result.data[14] = -(((l01 * l30) - (l02 * l32)) + (l03 * l33)) * l27
        result.data[3] = -(((l02 * l34) - (l03 * l35)) + (l04 * l36)) * l27
        result.data[7] = (((l01 * l34) - (l03 * l37)) + (l04 * l38)) * l27
        result.data[11] = -(((l01 * l35) - (l02 * l37)) + (l04 * l39)) * l27
        result.data[15] = (((l01 * l36) - (l02 * l38)) + (l03 * l39)) * l27
        return result
    }

}

func * (left: Matrix, right: Matrix) -> Matrix {
    var result: Matrix = Matrix()
    result.data[0] = left.data[0] * right.data[0] +
                     left.data[1] * right.data[4] +
                     left.data[2] * right.data[8] +
                     left.data[3] * right.data[12]

    result.data[1] = left.data[0] * right.data[1] +
                     left.data[1] * right.data[5] +
                     left.data[2] * right.data[9] +
                     left.data[3] * right.data[13]

    result.data[2] = left.data[0] * right.data[2] +
                     left.data[1] * right.data[6] +
                     left.data[2] * right.data[10] +
                     left.data[3] * right.data[14]

    result.data[3] = left.data[0] * right.data[3] +
                     left.data[1] * right.data[7] +
                     left.data[2] * right.data[11] +
                     left.data[3] * right.data[15]

    result.data[4] = left.data[4] * right.data[0] +
                     left.data[5] * right.data[4] +
                     left.data[6] * right.data[8] +
                     left.data[7] * right.data[12]

    result.data[5] = left.data[4] * right.data[1] +
                     left.data[5] * right.data[5] +
                     left.data[6] * right.data[9] +
                     left.data[7] * right.data[13]

    result.data[6] = left.data[4] * right.data[2] +
                     left.data[5] * right.data[6] +
                     left.data[6] * right.data[10] +
                     left.data[7] * right.data[14]

    result.data[7] = left.data[4] * right.data[3] +
                     left.data[5] * right.data[7] +
                     left.data[6] * right.data[11] +
                     left.data[7] * right.data[15]

    result.data[8] = left.data[8] * right.data[0] +
                     left.data[9] * right.data[4] +
                     left.data[10] * right.data[8] +
                     left.data[11] * right.data[12]

    result.data[9] = left.data[8] * right.data[1] +
                     left.data[9] * right.data[5] +
                     left.data[10] * right.data[9] +
                     left.data[11] * right.data[13]

    result.data[10] = left.data[8] * right.data[2] +
                      left.data[9] * right.data[6] +
                      left.data[10] * right.data[10] +
                      left.data[11] * right.data[14]

    result.data[11] = left.data[8] * right.data[3] +
                      left.data[9] * right.data[7] +
                      left.data[10] * right.data[11] +
                      left.data[11] * right.data[15]

    result.data[12] = left.data[12] * right.data[0] +
                      left.data[13] * right.data[4] +
                      left.data[14] * right.data[8] +
                      left.data[15] * right.data[12]

    result.data[13] = left.data[12] * right.data[1] +
                      left.data[13] * right.data[5] +
                      left.data[14] * right.data[9] +
                      left.data[15] * right.data[13]

    result.data[14] = left.data[12] * right.data[2] +
                      left.data[13] * right.data[6] +
                      left.data[14] * right.data[10] +
                      left.data[15] * right.data[14]

    result.data[15] = left.data[12] * right.data[3] +
                      left.data[13] * right.data[7] +
                      left.data[14] * right.data[11] +
                      left.data[15] * right.data[15]

    return result
}

func * (left: Vector3D, right: Matrix) -> Vector3D {
    return right * left
}

func * (left: Matrix, right: Vector3D) -> Vector3D {
    return Matrix.transformPoint(left: left, right: right)
}
