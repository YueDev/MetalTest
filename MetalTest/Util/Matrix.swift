/**
 * Video: https://www.youtube.com/watch?v=3Mo8fUoxCgk
 * File URL: https://github.com/smehus/MetalGame/blob/master/MetalGame/MatrixMath.swift
 *
 * Copyright © 2016 Caroline Begbie. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Mathematical functions are courtesy of Warren Moore and his
 * excellent book Metal By Example. Thank you.
 * http://metalbyexample.com
 *
 * Any mathematical errors are my own.
 *
 */

import simd

let pi = Float(Double.pi)

extension matrix_float4x4 {
    init(translationX x: Float, y: Float, z: Float) {
        self.init()
        columns = (
            SIMD4<Float>( 1,  0,  0,  0),
            SIMD4<Float>( 0,  1,  0,  0),
            SIMD4<Float>( 0,  0,  1,  0),
            SIMD4<Float>( x,  y,  z,  1)
        )
    }
    
    
    
    func translatedBy(x: Float, y: Float, z: Float) -> matrix_float4x4 {
        let translateMatrix = matrix_float4x4(translationX: x, y: y, z: z)
        return matrix_multiply(translateMatrix, self)
    }
    
    init(scaleX x: Float, y: Float, z: Float) {
        self.init()
        columns = (
            SIMD4<Float>( x,  0,  0,  0),
            SIMD4<Float>( 0,  y,  0,  0),
            SIMD4<Float>( 0,  0,  z,  0),
            SIMD4<Float>( 0,  0,  0,  1)
        )
    }
    
    func scaledBy(x: Float, y: Float, z: Float) -> matrix_float4x4 {
        let scaledMatrix = matrix_float4x4(scaleX: x, y: y, z: z)
        return matrix_multiply(scaledMatrix, self)
    }
    
    
    func rotatedBy(rotationAngle angle: Float,
                   x: Float, y: Float, z: Float) -> matrix_float4x4 {
        let rotationMatrix = getRotateMatrix(degree: angle, x1: x, y1: y, z1: z)
        return matrix_multiply(rotationMatrix, self)
    }
    
    func getRotateMatrix(degree: Float, x1: Float, y1: Float, z1: Float) -> matrix_float4x4 {
        
        var x = x1
        var y = y1
        var z = z1
        
        var rm = matrix_float4x4.init(1.0)
        
//        rm[0][3] = 0
//        rm[1][3] = 0
//        rm[2][3] = 0
//        rm[3][0] = 0
//        rm[3][1] = 0
//        rm[3][2] = 0
//        rm[3][3] = 1
        
        let a = degree * pi / 180.0
        let s = sin(a);
        let c = cos(a);
        
        if 1.0 == x && 0.0 == y && 0.0 == z {
                    rm[1][1] = c;
                    rm[2][2] = c;
                    rm[1][2] = s;
                    rm[2][1] = -s;
                    rm[0][1] = 0;
                    rm[0][2] = 0;
                    rm[1][0] = 0;
                    rm[2][0] = 0;
                    rm[0][0] = 1;
                } else if (0.0 == x && 1.0 == y && 0.0 == z) {
                    rm[0][0] = c;
                    rm[2][2] = c;
                    rm[2][0] = s;
                    rm[0][2] = -s;
                    rm[0][1] = 0;
                    rm[1][0] = 0;
                    rm[1][2] = 0;
                    rm[2][1] = 0;
                    rm[1][1] = 1;
                } else if (0.0 == x && 0.0 == y && 1.0 == z) {
                    rm[0][0] = c;
                    rm[1][1] = c;
                    rm[0][1] = s;
                    rm[1][0] = -s;
                    rm[0][2] = 0;
                    rm[1][2] = 0;
                    rm[2][0] = 0;
                    rm[2][1] = 0;
                    rm[2][2] = 1;
                } else {
                    let len = sqrt(x * x + y * y + z * z);
                    if (1.0 != len) {
                        let recipLen = 1.0 / len;
                        x *= recipLen;
                        y *= recipLen;
                        z *= recipLen;
                    }
                    let nc = 1.0 - c;
                    let xy = x * y;
                    let yz = y * z;
                    let zx = z * x;
                    let xs = x * s;
                    let ys = y * s;
                    let zs = z * s;
                    rm[0][0] = x * x * nc + c;
                    rm[1][0] = xy * nc - zs;
                    rm[2][0] = zx * nc + ys;
                    rm[0][1] = xy * nc + zs;
                    rm[1][1] = y * y * nc + c;
                    rm[2][1] = yz * nc - xs;
                    rm[0][2] = zx * nc - ys;
                    rm[1][2] = yz * nc + xs;
                    rm[2][2] = z * z * nc + c;
                }
        
        return rm
    }
    
    //view
    init(eyeX: Float, eyeY: Float, eyeZ: Float,
         centerX: Float, centerY: Float, centerZ: Float,
         upX: Float, upY: Float,upZ: Float) {
        self.init()
        
        // See the OpenGL GLUT documentation for gluLookAt for a description
        // of the algorithm. We implement it in a straightforward way:
        var fx = centerX - eyeX;
        var fy = centerY - eyeY;
        var fz = centerZ - eyeZ;
        
        // Normalize f
        let rlf = 1.0 / sqrt(fx * fx + fy * fy + fz * fz);
        fx *= rlf;
        fy *= rlf;
        fz *= rlf;
        
        // compute s = f x up (x means "cross product")
        var sx = fy * upZ - fz * upY;
        var sy = fz * upX - fx * upZ;
        var sz = fx * upY - fy * upX;
        
        // and normalize s
        let rls = 1.0 / sqrt(fx * fx + fy * fy + fz * fz);
        sx *= rls;
        sy *= rls;
        sz *= rls;
        
        // compute u = s x f
        let ux = sy * fz - sz * fy;
        let uy = sz * fx - sx * fz;
        let uz = sx * fy - sy * fx;
        
        self[0][0] = sx
        self[0][1] = ux
        self[0][2] = -fx
        self[0][3] = 0.0

        self[1][0] = sy
        self[1][1] = uy
        self[1][2] = -fy
        self[1][3] = 0.0

        self[2][0] = sz
        self[2][1] = uz
        self[2][2] = -fz
        self[2][3] = 0.0

        self[3][0] = 0.0
        self[3][1] = 0.0
        self[3][2] = 0.0
        self[3][3] = 1.0
        
        self[3][0] += self[0][0] * (-eyeX) + self[1][0] * (-eyeY) + self[2][0] * (-eyeZ)
        self[3][1] += self[0][1] * (-eyeX) + self[1][1] * (-eyeY) + self[2][1] * (-eyeZ)
        self[3][2] += self[0][2] * (-eyeX) + self[1][2] * (-eyeY) + self[2][2] * (-eyeZ)
        self[3][3] += self[0][3] * (-eyeX) + self[1][3] * (-eyeY) + self[2][3] * (-eyeZ)
    }
    
    //projection
    init(fovy: Float, aspect: Float, zNear: Float, zFar: Float) {
        self.init()

        let f = 1.0 / tan(fovy * pi / 360.0);
        let rangeReciprocal = 1.0 / (zNear - zFar);

            self[0][0] = f / aspect
            self[0][1] = 0.0
            self[0][2] = 0.0
            self[0][3] = 0.0

            self[1][0] = 0.0
            self[1][1] = f
            self[1][2] = 0.0
            self[1][3] = 0.0

            self[2][0] = 0.0
            self[2][1] = 0.0
            self[2][2] = (zFar + zNear) * rangeReciprocal
            self[2][3] = -1.0

            self[3][0] = 0.0
            self[3][1] = 0.0
            self[3][2] = 2.0 * zFar * zNear * rangeReciprocal
            self[3][3] = 0.0
    }
    
}

extension matrix_float4x4: CustomReflectable {
    
    public var customMirror: Mirror {
        let c00 = String(format: "%  .4f", columns.0.x)
        let c01 = String(format: "%  .4f", columns.0.y)
        let c02 = String(format: "%  .4f", columns.0.z)
        let c03 = String(format: "%  .4f", columns.0.w)
        
        let c10 = String(format: "%  .4f", columns.1.x)
        let c11 = String(format: "%  .4f", columns.1.y)
        let c12 = String(format: "%  .4f", columns.1.z)
        let c13 = String(format: "%  .4f", columns.1.w)
        
        let c20 = String(format: "%  .4f", columns.2.x)
        let c21 = String(format: "%  .4f", columns.2.y)
        let c22 = String(format: "%  .4f", columns.2.z)
        let c23 = String(format: "%  .4f", columns.2.w)
        
        let c30 = String(format: "%  .4f", columns.3.x)
        let c31 = String(format: "%  .4f", columns.3.y)
        let c32 = String(format: "%  .4f", columns.3.z)
        let c33 = String(format: "%  .4f", columns.3.w)
        
        
        let children = KeyValuePairs<String, Any>(dictionaryLiteral:
                                                    (" ", "\(c00) \(c01) \(c02) \(c03)"),
                                                  (" ", "\(c10) \(c11) \(c12) \(c13)"),
                                                  (" ", "\(c20) \(c21) \(c22) \(c23)"),
                                                  (" ", "\(c30) \(c31) \(c32) \(c33)")
        )
        return Mirror(matrix_float4x4.self, children: children)
    }
}

extension SIMD4<Float>: CustomReflectable {
    
    public var customMirror: Mirror {
        let sx = String(format: "%  .4f", x)
        let sy = String(format: "%  .4f", y)
        let sz = String(format: "%  .4f", z)
        let sw = String(format: "%  .4f", w)
        
        let children = KeyValuePairs<String, Any>(dictionaryLiteral:
                                                    (" ", "\(sx) \(sy) \(sz) \(sw)")
        )
        return Mirror(SIMD4<Float>.self, children: children)
    }
}
