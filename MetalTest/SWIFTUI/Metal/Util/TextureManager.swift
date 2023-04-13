//
// Created by YUE on 2022/11/19.
//

import Foundation
import UIKit
import Metal
import MetalKit

//纹理相关方法

enum TextureManager {
    
    private static var sIndex = 0
    
    static func getPeopleTextureName() -> String {
        let index = sIndex % 8
        sIndex += 1
        return "people\(index)"
    }
    

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

    static func getRandomBgColor() -> (Double, Double, Double, Double) {
        let index = Int.random(in: 0...colors.count - 1)
        return colors[index]
    }

    static func defaultTextureByAssets(device: MTLDevice?, name: String) -> MTLTexture? {

        guard let image = UIImage.init(named: name)?.centerInside(width: Double(defaultWidth), height: Double(defaultHeight)) else {
            return nil
        }
        return toMTLTexture2(image: image, device: device)

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
               bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
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

    static func textTexture(text: String, device: MTLDevice?) -> MTLTexture? {
        let label = UILabel()
        label.text = text
        label.textColor = .orange
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.backgroundColor = UIColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.2)
        label.alpha = 1.0

        label.numberOfLines = .max
        label.sizeToFit()

        guard let uiImage = label.createUIImage() else {
            return nil
        }

        print("ui image: \(uiImage.size)")
        return toMTLTexture2(image: uiImage, device: device)
    }


    //use TextureLoader
    static func toMTLTexture2(image: UIImage, device: MTLDevice?) -> MTLTexture? {
        guard let device = device,
              let cgImage = image.cgImage
        else {
            return nil
        }

        let textureLoader = MTKTextureLoader(device: device)
        
        //好像要把srgb强制为0关掉，否则偏色严重
        return try? textureLoader.newTexture(cgImage: cgImage, options: [.SRGB: 0])
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


    static func newTextureForKernel(device: MTLDevice, width:Int = defaultWidth, height: Int = defaultHeight) -> MTLTexture? {

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
               width: width, height: height, mipmapped: false)
        // textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        return texture
    }

    
    private func defaultSamplerState(device: MTLDevice) -> MTLSamplerState? {
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
    
}
