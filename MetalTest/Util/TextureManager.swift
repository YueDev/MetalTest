//
// Created by YUE on 2022/11/19.
//

import Foundation
import UIKit
import Metal

//纹理相关方法

enum TextureManager {

    private static let defaultWidth = 1024
    private static let defaultHeight = 1024

    private static let colors = [
        (0.2, 0.3, 0.4, 1.0),
        (0.5, 0.5, 0.3, 1.0),
        (0.6, 0.3, 0.6, 1.0),
        (0.3, 0.7, 0.5, 1.0),
        (0.4, 0.5, 0.2, 1.0),
        (0.6, 0.2, 0.1, 1.0),
        (0.5, 0.7, 0.3, 1.0),
    ]

    static func getRandomBgColor() ->(Double, Double, Double, Double) {
        let index = Int.random(in: 0...colors.count - 1)
        return colors[index]
    }

    static func defaultTextureByAssets(device: MTLDevice?, name: String) -> MTLTexture? {

        guard let image = UIImage.init(named: name)?.centerInside(width: Double(defaultWidth), height: Double(defaultHeight)) else {
            return nil
        }
        return toMTLTexture(image: image, device: device)
    }

    static func emptyTexture(device: MTLDevice?, useMSAA: Bool = false) -> MTLTexture? {
        
        guard let device = device else {
            return nil
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
               width: defaultWidth,
               height: defaultHeight,
               mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        
        if useMSAA {
            textureDescriptor.textureType = .type2DMultisample
            textureDescriptor.sampleCount = 4
            
        }

        
        return device.makeTexture(descriptor: textureDescriptor)
        
    }
    
    
    static func toMTLTexture(image: UIImage, device: MTLDevice?) -> MTLTexture? {

        guard let device = device else {
            return nil
        }

        let imageRef = (image.cgImage)!
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.size)
        let bytesPerPixel: Int = 4
        let bytesPerRow: Int = bytesPerPixel * width
        let bitsPerComponent: Int = 8
        let bitmapContext = CGContext(data: rawData,
               width: width,
               height: height,
               bitsPerComponent: bitsPerComponent,
               bytesPerRow: bytesPerRow,
               space: colorSpace,
               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        bitmapContext?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
               width: width,
               height: height,
               mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let texture: MTLTexture? = device.makeTexture(descriptor: textureDescriptor)
        let region: MTLRegion = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: rawData!, bytesPerRow: bytesPerRow)
        free(rawData)

        return texture
    }



    static func defaultSamplerState(device: MTLDevice) -> MTLSamplerState? {
        let samplerDescriptor = MTLSamplerDescriptor()
        //线性采样 默认是临近采样
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        //以下的可以不写，默认值就很好
        //s r t三个坐标的 环绕方式，默认就是clampToEdge
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.rAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        //标准化到0 1 默认true
        samplerDescriptor.normalizedCoordinates = true
        return device.makeSamplerState(descriptor: samplerDescriptor)
    }


    static func newTextureForKernel(device: MTLDevice) -> MTLTexture?{

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
               width: defaultWidth, height: defaultHeight, mipmapped: false)
        // textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]

        let texture = device.makeTexture(descriptor: textureDescriptor)
        return texture
    }

}
