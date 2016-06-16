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
    
    static func transpose(matrix:Matrix) -> Matrix{
        var result:Matrix = Matrix();
        result.m[0] = matrix.m[0];
        result.m[1] = matrix.m[4];
        result.m[2] = matrix.m[8];
        result.m[3] = matrix.m[12];
        result.m[4] = matrix.m[1];
        result.m[5] = matrix.m[5];
        result.m[6] = matrix.m[9];
        result.m[7] = matrix.m[13];
        result.m[8] = matrix.m[2];
        result.m[9] = matrix.m[6];
        result.m[10] = matrix.m[10];
        result.m[11] = matrix.m[14];
        result.m[12] = matrix.m[3];
        result.m[13] = matrix.m[7];
        result.m[14] = matrix.m[11];
        result.m[15] = matrix.m[15];
        return result;
    }
    
    static func inverse(matrix:Matrix) -> Matrix{
        var result:Matrix = Matrix()
        var l1 = matrix.m[0];
        var l2 = matrix.m[1];
        var l3 = matrix.m[2];
        var l4 = matrix.m[3];
        var l5 = matrix.m[4];
        var l6 = matrix.m[5];
        var l7 = matrix.m[6];
        var l8 = matrix.m[7];
        var l9 = matrix.m[8];
        var l10 = matrix.m[9];
        var l11 = matrix.m[10];
        var l12 = matrix.m[11];
        var l13 = matrix.m[12];
        var l14 = matrix.m[13];
        var l15 = matrix.m[14];
        var l16 = matrix.m[15];
        var l17 = (l11 * l16) - (l12 * l15);
        var l18 = (l10 * l16) - (l12 * l14);
        var l19 = (l10 * l15) - (l11 * l14);
        var l20 = (l9 * l16) - (l12 * l13);
        var l21 = (l9 * l15) - (l11 * l13);
        var l22 = (l9 * l14) - (l10 * l13);
        var l23 = ((l6 * l17) - (l7 * l18)) + (l8 * l19);
        var l24 = -(((l5 * l17) - (l7 * l20)) + (l8 * l21));
        var l25 = ((l5 * l18) - (l6 * l20)) + (l8 * l22);
        var l26 = -(((l5 * l19) - (l6 * l21)) + (l7 * l22));
        var l27 = 1.0 / ((((l1 * l23) + (l2 * l24)) + (l3 * l25)) + (l4 * l26));
        var l28 = (l7 * l16) - (l8 * l15);
        var l29 = (l6 * l16) - (l8 * l14);
        var l30 = (l6 * l15) - (l7 * l14);
        var l31 = (l5 * l16) - (l8 * l13);
        var l32 = (l5 * l15) - (l7 * l13);
        var l33 = (l5 * l14) - (l6 * l13);
        var l34 = (l7 * l12) - (l8 * l11);
        var l35 = (l6 * l12) - (l8 * l10);
        var l36 = (l6 * l11) - (l7 * l10);
        var l37 = (l5 * l12) - (l8 * l9);
        var l38 = (l5 * l11) - (l7 * l9);
        var l39 = (l5 * l10) - (l6 * l9);
        result.m[0] = l23 * l27;
        result.m[4] = l24 * l27;
        result.m[8] = l25 * l27;
        result.m[12] = l26 * l27;
        result.m[1] = -(((l2 * l17) - (l3 * l18)) + (l4 * l19)) * l27;
        result.m[5] = (((l1 * l17) - (l3 * l20)) + (l4 * l21)) * l27;
        result.m[9] = -(((l1 * l18) - (l2 * l20)) + (l4 * l22)) * l27;
        result.m[13] = (((l1 * l19) - (l2 * l21)) + (l3 * l22)) * l27;
        result.m[2] = (((l2 * l28) - (l3 * l29)) + (l4 * l30)) * l27;
        result.m[6] = -(((l1 * l28) - (l3 * l31)) + (l4 * l32)) * l27;
        result.m[10] = (((l1 * l29) - (l2 * l31)) + (l4 * l33)) * l27;
        result.m[14] = -(((l1 * l30) - (l2 * l32)) + (l3 * l33)) * l27;
        result.m[3] = -(((l2 * l34) - (l3 * l35)) + (l4 * l36)) * l27;
        result.m[7] = (((l1 * l34) - (l3 * l37)) + (l4 * l38)) * l27;
        result.m[11] = -(((l1 * l35) - (l2 * l37)) + (l4 * l39)) * l27;
        result.m[15] = (((l1 * l36) - (l2 * l38)) + (l3 * l39)) * l27;
        return result
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
