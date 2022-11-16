//
//  ViewController.swift
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

import UIKit
import Metal
import MetalKit
import QuartzCore
import Foundation
import RxSwift
import RxCocoa

import simd

//顶点的结构

//由于用的是MTLVertexDescriptor描述顶点数据，因此不需要定义oc结构给metal做桥接。
//metal的着色器里有对应的结构 VertexIn
//需要倒入simd　floatX被遗弃，提示用SIMD<FloatX>代替
//尽量别用float2, 用的话往后放有对齐 float3和float4没有
struct VertexModel {
    //坐标和纹理的坐标
    var positionAndUV: SIMD4<Float>
    var color1: SIMD4<Float>
    var color2: SIMD4<Float>
}


class ViewController: UIViewController {

    let disposeBag = DisposeBag()

    private lazy var device = {
        MTLCreateSystemDefaultDevice()
    }()

    private lazy var metalLayer = {
        CAMetalLayer()
    }()

    private var vertexBuffer: MTLBuffer? = nil
    private var fragmentBuffer: MTLBuffer? = nil

    private var renderPass: MTLRenderPassDescriptor? = nil

    private var pipeLineState: MTLRenderPipelineState? = nil

    private var commandQueue: MTLCommandQueue? = nil

    private var texture1: MTLTexture? = nil
    private var texture2: MTLTexture? = nil
    private var samplerState: MTLSamplerState? = nil

    
    override func viewDidLayoutSubviews() {
        metalLayer.frame = view.layer.frame.inset(by: view.safeAreaInsets)
        metalLayer.setNeedsDisplay()

    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.backgroundColor = .lightGray
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.delegate = self

        view.layer.addSublayer(metalLayer)

        let button = UIButton.init(type: .system)
        button.setTitle("Refresh", for: .normal)
        button.sizeToFit()
        button.backgroundColor = .secondarySystemBackground
        button.frame = button.frame.offsetBy(dx: 50, dy: 50)


        button.rx.tap.subscribe { [weak self] event in
                self?.metalLayer.setNeedsDisplay()
            }
            .disposed(by: disposeBag)

        view.addSubview(button)


        do {
            try readyForDraw()
            startRender()
        } catch {
            print(error)
            return
        }

    }


    //渲染 draw call

    private func render() {
        print("render once")
        guard let pipeLineState = pipeLineState,
              let renderPass = renderPass
        else {
            return
        }

        guard let drawable = metalLayer.nextDrawable() else {
            return
        }
        //render pass设置纹理
        renderPass.colorAttachments[0].texture = drawable.texture

        //生成command buffer 这里放到渲染外初始化不行
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            return
        }

        //生成command encoder
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
            return
        }
        //设置renderEncoder 编码渲染的内容
        //设置pipeline state
        renderEncoder.setRenderPipelineState(pipeLineState)
        //发送顶点数据  这个好像没法和opengl一样在渲染之前设置
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        //发送fragment的uniform， 也是通过buffer实现的
        renderEncoder.setFragmentBuffer(fragmentBuffer, offset: 0, index: 0)
        //设置纹理和采样器
        renderEncoder.setFragmentTexture(texture1, index: 0)
        renderEncoder.setFragmentTexture(texture2, index: 1)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        //绘制三角形，1个
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        //endEncoding 结束渲染编码
        renderEncoder.endEncoding()

        //commandBuffer 设置drawable并提交
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }


    //渲染之前的准备

    private func readyForDraw() throws {

        guard let device = self.device else {
            return
        }

        //顶点数据
        let vertexData = [
            VertexModel(positionAndUV: SIMD4<Float>(-0.5, 0.5, 0.0, 0.0), color1: SIMD4<Float>(0.8, 0.8, 0.2, 1.0), color2: SIMD4<Float>(0.7, 0.0, 0.0, 0.0)),
            VertexModel(positionAndUV: SIMD4<Float>(-0.5, -0.5, 0.0, 1.0), color1: SIMD4<Float>(0.8, 0.8, 0.2, 1.0), color2: SIMD4<Float>(0.0, 0.7, 0.0, 0.0)),
            VertexModel(positionAndUV: SIMD4<Float>(0.5, 0.5, 1.0, 0.0), color1: SIMD4<Float>(0.8, 0.8, 0.2, 1.0), color2: SIMD4<Float>(0.0, 0.0, 0.7, 0.0)),
            VertexModel(positionAndUV: SIMD4<Float>(0.5, -0.5, 1.0, 1.0), color1: SIMD4<Float>(0.8, 0.8, 0.2, 1.0), color2: SIMD4<Float>(0.0, 0.0, 0.0, 0.0)),
        ]


        let dataSize = MemoryLayout.stride(ofValue: vertexData[0]) * vertexData.count

        //生成顶点vertexBuffer
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])

        //生成fragment buffer 这里和opengl的uniform差不多，给fragment传随时刷新的数据
        var fragmentData: Float = 0
        //这里不是数组的话，必须加上&
        fragmentBuffer = device.makeBuffer(bytes: &fragmentData, length: MemoryLayout.stride(ofValue: fragmentData), options: [])

        //生成shader program
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            return
        }

        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")

        //设置pipeLineDescriptor
        let pipeLineDescriptor = MTLRenderPipelineDescriptor()
        pipeLineDescriptor.vertexFunction = vertexProgram
        pipeLineDescriptor.fragmentFunction = fragmentProgram

        //用MTLVertexDescriptor来描述顶点数据 有点类似OPENGL的描述buffer的方法
        //尽量别用float2  float2 需要8个字节来对其，所以需要size+alignment
        //float3 是16个字节 不需要对齐　float4也不需要对齐　
        let vertexDescriptor = MTLVertexDescriptor()
        //VertexModel的第一个数据 position
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        //VertexModel的第二个数据 color1
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD4<Float>>.size
        //VertexModel的第三个数据 color2
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD4<Float>>.size + MemoryLayout<SIMD4<Float>>.size

        // 每组数据的步长  这个layout应该和着色器里的buffer(0)一样
        vertexDescriptor.layouts[0].stride = MemoryLayout.stride(ofValue: vertexData[0])

        pipeLineDescriptor.vertexDescriptor = vertexDescriptor

        pipeLineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipeLineState = try device.makeRenderPipelineState(descriptor: pipeLineDescriptor)

        //生成命令队列 和 命令buffer
        commandQueue = device.makeCommandQueue()

        //render pass 可以设置color clear之类的
        renderPass = MTLRenderPassDescriptor()
        renderPass?.colorAttachments[0].loadAction = .clear
        renderPass?.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.4, 0.3, 1.0)
        //生成纹理 采样器
        texture1 = ViewController.defaultTextureByAssets(device: device, name: "test1")
        texture2 = ViewController.defaultTextureByAssets(device: device, name: "test2")
        samplerState = ViewController.defaultSamplerState(device: device)
    }


    private static func defaultTextureByAssets(device: MTLDevice?, name: String) -> MTLTexture? {
        
//        guard let image = UIImage.init(named: name)?.centerInside(width: 2000, height:2000),
//              let device = device
//        else {
//            return nil
//        }

        
//        return try? loader.newTexture(cgImage: cgImage, options: [.textureUsage:])
        
        guard let image = UIImage.init(named: name)?.centerInside(width: 2000, height:2000) else {
            return nil
        }
        return image.toMTLTexture(device: device)
        
    }


    private static func defaultSamplerState(device: MTLDevice) -> MTLSamplerState? {
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


    //game loop 根据屏幕的刷新来更新画面

    @MainActor
    private func startRender() {

        let timer = CADisplayLink(target: self, selector: #selector(gameLoop))
        timer.add(to: RunLoop.main, forMode: .default)

        //停止自动渲染  需要@MainActor
//        Task {
//            try! await Task.sleep(nanoseconds: 3_000_000_000)
//        //释放监听。临时暂停可以使用isPause = true  这都需要主线程
//            timer.remove(from: RunLoop.main, forMode: .default)
//        }
    }

    @objc func gameLoop() {
        autoreleasepool {
            //改变progress
            guard let fragmentBufferPtr = fragmentBuffer?.contents().bindMemory(to: Float.self, capacity: 1) else {
                return
            }
            //让进度在0 - 1之间渐变
            let time = CACurrentMediaTime()
            let progress = (sin(time) + 1.0) / 2.0
            fragmentBufferPtr.pointee = Float(progress)
            render()
        }
    }
}


//设置代理，刷新的时候用setNeedDisplay即可

extension ViewController: CALayerDelegate {
    public func display(_ layer: CALayer) {
        render()
    }
}



public extension UIImage {
    
    func toMTLTexture(device: MTLDevice?) -> MTLTexture? {
        
        guard let device = device else {
            return nil
        }
        
        let imageRef = (self.cgImage)!
        let width = Int(size.width)
        let height = Int(size.height)
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
}

