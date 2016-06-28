//
//  Vector2D.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/26/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import Foundation

struct Vector2D{
    let x:Float
    let y:Float
    
    func normalized() -> Vector2D{
        let len = length();
        let scale = 1.0 / len;
        return Vector2D(x: x*scale, y: y*scale)
    }
    
    func abs() -> Vector2D{
        return Vector2D(x: fabsf(x), y: fabsf(y));
    }
    
    func length() -> Float{
        return sqrt(x * x + y * y);
    }
    
    func toString() -> String{
        return "(\(x),\(y)";
    }
    
    func rotate(angle:Float) -> Vector2D{
        let cosine:Float = cos(angle)
        let sine = sin(angle)
        
        let x = self.x * cosine - self.y * sine
        let y = self.x * sine + self.y * cosine
        
        return Vector2D(x: x, y: y)
    }
    
    static func up() -> Vector2D {
        return Vector2D(x: 0.0, y: 1.0)
    }
    
    static func down() -> Vector2D {
        return Vector2D(x: 0.0, y: -1.0)
    }
    
    static func right() -> Vector2D {
        return Vector2D(x: 1.0, y: 0.0)
    }
    
    static func left() -> Vector2D {
        return Vector2D(x: -1.0, y: 0.0)
    }
}

prefix func - (vector: Vector2D) -> Vector2D {
    return Vector2D(x:-vector.x, y:-vector.y)
}

func + (left: Vector2D, right: Vector2D) -> Vector2D{
    return Vector2D(x:left.x + right.x, y:left.y + right.y)
}

func + (left: Vector2D, right: Float) -> Vector2D{
    return Vector2D(x:left.x + right, y:left.y + right)
}

func - (left: Vector2D, right: Vector2D) -> Vector2D{
    return Vector2D(x:left.x - right.x, y:left.y - right.y)
}

func - (left: Vector2D, right: Float) -> Vector2D{
    return Vector2D(x:left.x - right, y:left.y - right)
}

func * (left: Vector2D, right: Vector2D) -> Vector2D{
    return Vector2D(x:left.x * right.x, y:left.y * right.y)
}

func * (left: Vector2D, right: Float) -> Vector2D{
    return Vector2D(x:left.x * right, y:left.y * right)
}

func * (left: Float, right: Vector2D) -> Vector2D{
    return right * left
}

func / (left: Vector2D, right: Vector2D) -> Vector2D{
    return Vector2D(x:left.x / right.x, y:left.y / right.y)
}

func / (left: Vector2D, right: Float) -> Vector2D{
    return Vector2D(x:left.x / right, y:left.y / right)
}

func min (left: Vector2D, right: Vector2D) -> Vector2D{
    return Vector2D(x: min(left.x, right.x), y: min(left.y, right.y))
}

func max (left: Vector2D, right: Vector2D) -> Vector2D{
    return Vector2D(x: max(left.x, right.x), y: max(left.y, right.y))
}

func ⋅ (left: Vector2D, right: Vector2D) -> Float{
    return left.x * right.x + left.y * right.y
}