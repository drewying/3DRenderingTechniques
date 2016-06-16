//
//  Matrix.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/20/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import UIKit


//This matrix assumes a LH coordinate system

struct Matrix{
    var m:[Float] = [
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0
    ];
    
    static func identityMatrix() -> Matrix{
        var matrix = Matrix();
        matrix.m = [
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        ];
        return matrix
    }
    
    static func zeroMatrix() -> Matrix{
        var matrix = Matrix();
        matrix.m = [
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0
        ];
        return matrix;
    }
    
    static func perspective(fov:Float, aspectRatio:Float, zNear:Float, zFar:Float) -> Matrix{
        var result = zeroMatrix()
        let tan = 1.0/tanf(fov * 0.5)
        result.m[0] = tan/aspectRatio
        result.m[5] = tan
        result.m[10] = -zFar / (zNear - zFar)
        result.m[11] = 1.0
        result.m[14] = (zNear * zFar) / (zNear - zFar)
        
        /*result.m[0] = tan * aspectRatio
        result.m[5] = tan
        result.m[10] = (zFar + zNear) / (zFar - zNear)
        result.m[11] = 1.0
        result.m[14] = (2.0 * zNear * zFar) / (zNear - zFar);*/
        return result
    }
    
    static func lookAt(cameraPosition:Vector3D, cameraTarget:Vector3D, cameraUp:Vector3D) -> Matrix{
        let zAxis = (cameraPosition - cameraTarget).normalized()
        let xAxis = (cameraUp × zAxis).normalized()
        let yAxis = zAxis × xAxis
        
        let x = -(xAxis ⋅ cameraPosition)
        let y = -(yAxis ⋅ cameraPosition)
        let z = -(zAxis ⋅ cameraPosition)
        
        
        var result:Matrix = Matrix()
        result.m = [
            xAxis.x, yAxis.x, zAxis.x, 0.0,
            xAxis.y, yAxis.y, zAxis.y, 0.0,
            xAxis.z, yAxis.z, zAxis.z, 0.0,
                  x,       y,       z, 1.0
        ]
        return result
    }
    
    static func scale(vector:Vector3D) -> Matrix{
        var result = zeroMatrix();
        result.m[0] = vector.x;
        result.m[5] = vector.y;
        result.m[10] = vector.z;
        result.m[15] = 1.0;
        return result
    }
    
    static func translate(vector:Vector3D) -> Matrix{
        var result = identityMatrix()
        result.m[12] = vector.x
        result.m[13] = vector.y
        result.m[14] = vector.z
        return result
    }
    
    static func rotateX(angle:Float) -> Matrix {
        let cosine:Float = cos(angle)
        let sine:Float = sin(angle)
    
        var result = zeroMatrix()
        result.m[0] = 1.0;
        result.m[15] = 1.0;
        result.m[5] = cosine
        result.m[10] = cosine
        result.m[9] = -sine
        result.m[6] = sine
    
        return result
    }
    
    static func rotateY(angle:Float) -> Matrix {
        let cosine:Float = cos(angle);
        let sine:Float = sin(angle);
    
        var result = zeroMatrix()
        result.m[5] = 1.0
        result.m[15] = 1.0
        result.m[0] = cosine
        result.m[2] = -sine
        result.m[8] = sine
        result.m[10] = cosine
        
        return result
    }
    
    static func rotateZ(angle:Float) -> Matrix {
        let cosine:Float = cos(angle);
        let sine:Float = sin(angle);
    
        var result = zeroMatrix()
        result.m[10] = 1.0
        result.m[15] = 1.0
        result.m[0] = cosine
        result.m[1] = sine
        result.m[4] = -sine
        result.m[5] = cosine
    
        return result
    }
    
    static func transformVector(left:Matrix, right:Vector3D) -> Vector3D {
        let x:Float = right.x * left.m[0] + right.y * left.m[4] + right.z * left.m[6] + left.m[8]
        let y:Float = right.x * left.m[1] + right.y * left.m[5] + right.z * left.m[7] + left.m[9]
        let z:Float = right.x * left.m[2] + right.y * left.m[6] + right.z * left.m[8] + left.m[10]
        return Vector3D(x:x, y:y, z:z)
    }
    
    static func transformPoint(left:Matrix, right:Vector3D) -> Vector3D{
        
        let x:Float = right.x * left.m[0] + right.y * left.m[4] + right.z * left.m[8] + left.m[12]
        let y:Float = right.x * left.m[1] + right.y * left.m[5] + right.z * left.m[9] + left.m[13]
        let z:Float = right.x * left.m[2] + right.y * left.m[6] + right.z * left.m[10] + left.m[14]
        let w:Float = right.x * left.m[3] + right.y * left.m[7] + right.z * left.m[11] + left.m[15]
        return Vector3D(x:x/w, y:y/w, z:z/w)
    }

}

func * (left: Matrix, right: Matrix) -> Matrix {
    var result:Matrix = Matrix();
    result.m[0] = left.m[0] * right.m[0] + left.m[1] * right.m[4] + left.m[2] * right.m[8] + left.m[3] * right.m[12]
    result.m[1] = left.m[0] * right.m[1] + left.m[1] * right.m[5] + left.m[2] * right.m[9] + left.m[3] * right.m[13]
    result.m[2] = left.m[0] * right.m[2] + left.m[1] * right.m[6] + left.m[2] * right.m[10] + left.m[3] * right.m[14]
    result.m[3] = left.m[0] * right.m[3] + left.m[1] * right.m[7] + left.m[2] * right.m[11] + left.m[3] * right.m[15]
    result.m[4] = left.m[4] * right.m[0] + left.m[5] * right.m[4] + left.m[6] * right.m[8] + left.m[7] * right.m[12]
    result.m[5] = left.m[4] * right.m[1] + left.m[5] * right.m[5] + left.m[6] * right.m[9] + left.m[7] * right.m[13]
    result.m[6] = left.m[4] * right.m[2] + left.m[5] * right.m[6] + left.m[6] * right.m[10] + left.m[7] * right.m[14]
    result.m[7] = left.m[4] * right.m[3] + left.m[5] * right.m[7] + left.m[6] * right.m[11] + left.m[7] * right.m[15]
    result.m[8] = left.m[8] * right.m[0] + left.m[9] * right.m[4] + left.m[10] * right.m[8] + left.m[11] * right.m[12]
    result.m[9] = left.m[8] * right.m[1] + left.m[9] * right.m[5] + left.m[10] * right.m[9] + left.m[11] * right.m[13]
    result.m[10] = left.m[8] * right.m[2] + left.m[9] * right.m[6] + left.m[10] * right.m[10] + left.m[11] * right.m[14]
    result.m[11] = left.m[8] * right.m[3] + left.m[9] * right.m[7] + left.m[10] * right.m[11] + left.m[11] * right.m[15]
    result.m[12] = left.m[12] * right.m[0] + left.m[13] * right.m[4] + left.m[14] * right.m[8] + left.m[15] * right.m[12]
    result.m[13] = left.m[12] * right.m[1] + left.m[13] * right.m[5] + left.m[14] * right.m[9] + left.m[15] * right.m[13]
    result.m[14] = left.m[12] * right.m[2] + left.m[13] * right.m[6] + left.m[14] * right.m[10] + left.m[15] * right.m[14]
    result.m[15] = left.m[12] * right.m[3] + left.m[13] * right.m[7] + left.m[14] * right.m[11] + left.m[15] * right.m[15]
    return result
}

func * (left: Vector3D, right: Matrix) -> Vector3D {
    return right * left;
}

func * (left: Matrix, right: Vector3D) -> Vector3D {
    return Matrix.transformPoint(left, right: right)
}
