//
//  MetalViewController.swift
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
import SnapKit

import simd

//顶点的结构

//由于用的是MTLVertexDescriptor描述顶点数据，因此不需要定义oc结构给metal做桥接。
//metal的着色器里有对应的结构 VertexIn
//需要倒入simd　floatX被遗弃，提示用SIMD<FloatX>代替
//尽量别用float2, 用的话往后放有对齐 float3和float4没有


class MetalViewController: UIViewController {

    let colors = [
        (0.2, 0.3, 0.4, 1.0),
        (0.5, 0.5, 0.3, 1.0),
        (0.6, 0.3, 0.6, 1.0),
        (0.3, 0.7, 0.5, 1.0),
    ]

    private var vertexShaderName = "simple_vertex"
    private var fragmentShaderName = "simple_fragment_mix"

    private let disposeBag = DisposeBag()

    private lazy var slider = {
        UISlider()
    }()

    private lazy var device = {
        MTLCreateSystemDefaultDevice()
    }()

    private lazy var metalLayer = {
        CAMetalLayer()
    }()

    private var vertexBuffer: MTLBuffer? = nil
    private var fragmentBuffer: MTLBuffer? = nil
    private var vertexScaleBuffer: MTLBuffer? = nil

    private var renderPass: MTLRenderPassDescriptor? = nil

    private var pipeLineState: MTLRenderPipelineState? = nil

    private var commandQueue: MTLCommandQueue? = nil

    private var texture1: MTLTexture? = nil
    private var texture2: MTLTexture? = nil
    private var samplerState: MTLSamplerState? = nil



    func setShaderName(_ vertex: String, _ fragment: String) {
        vertexShaderName = vertex
        fragmentShaderName = fragment
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.delegate = self

        view.layer.addSublayer(metalLayer)

        slider.rx.value.subscribe { [weak self] in
                self?.updateProgress($0)
            }
            .disposed(by: disposeBag)

        view.addSubview(slider)

        do {
            try readyForDraw()
        } catch {
            print(error)
            return
        }
    }


    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        slider.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.left.equalTo(view.safeAreaLayoutGuide).offset(32)
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-32)
        }

        metalLayer.frame = view.layer.frame

        //计算图片的缩放
        let w = Float(metalLayer.frame.width)
        let h = Float(metalLayer.frame.height)

        var scaleW: Float = 1.0
        var scaleH: Float = 1.0
        //图片比例改了只改这里即可 上边scaleW scaleH不要动
        let picScale: Float = 1.0 / 1.0
        if (w / h) > picScale {
            //窗口比图片宽，图片被拉伸了，要缩放图片的宽
            scaleW = scaleH * picScale * h / w
        } else {
            scaleH = scaleW / picScale * w / h
        }
        updateScale(scaleW, scaleH)
    }


    //渲染 draw call

    private func render() {
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
        //发送vertex的uniform
        renderEncoder.setVertexBuffer(vertexScaleBuffer, offset: 0, index: 1)
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
            SIMD4<Float>(-0.9, 0.9, 0.0, 0.0),
            SIMD4<Float>(-0.9, -0.9, 0.0, 1.0),
            SIMD4<Float>(0.9, 0.9, 1.0, 0.0),
            SIMD4<Float>(0.9, -0.9, 1.0, 1.0),
        ]


        let dataSize = MemoryLayout.stride(ofValue: vertexData[0]) * vertexData.count

        //生成顶点vertexBuffer
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])

        //缩放，这里没使用matrix，直接算的图片和layer的比例，传给顶点
        var vertexScaleData = SIMD2<Float>(1.0, 1.0)
        vertexScaleBuffer = device.makeBuffer(bytes: &vertexScaleData, length: MemoryLayout.stride(ofValue: vertexScaleData), options: [])

        //生成fragment buffer 这里和opengl的uniform差不多，给fragment传随时刷新的数据
        var fragmentData: Float = 0
        //这里不是数组的话，必须加上&
        fragmentBuffer = device.makeBuffer(bytes: &fragmentData, length: MemoryLayout.stride(ofValue: fragmentData), options: [])

        //生成shader program
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            return
        }

        let vertexProgram = defaultLibrary.makeFunction(name: vertexShaderName)
        let fragmentProgram = defaultLibrary.makeFunction(name: fragmentShaderName)

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

        let index = Int.random(in: 0...colors.count - 1)
        let bgColor = colors[index]

        renderPass?.colorAttachments[0].clearColor = MTLClearColorMake(bgColor.0, bgColor.1, bgColor.2, bgColor.3)
        //生成纹理 采样器
        texture1 = MetalViewController.defaultTextureByAssets(device: device, name: "test1")
        texture2 = MetalViewController.defaultTextureByAssets(device: device, name: "test2")
        samplerState = MetalViewController.defaultSamplerState(device: device)
    }


    //更新图片比例

    private func updateScale(_ scaleX: Float, _ scaleY: Float) {
        guard let vertexBufferPtr = vertexScaleBuffer?.contents().bindMemory(to: SIMD2<Float>.self, capacity: 1) else {
            return
        }
        vertexBufferPtr.pointee = SIMD2<Float>(scaleX, scaleY)
        metalLayer.setNeedsDisplay()
    }

    //更新进度

    private func updateProgress(_ value: Float) {
        guard let fragmentBufferPtr = fragmentBuffer?.contents().bindMemory(to: Float.self, capacity: 1) else {
            return
        }
        fragmentBufferPtr.pointee = value
        metalLayer.setNeedsDisplay()
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
            metalLayer.setNeedsDisplay()
        }
    }
}

//设置代理，刷新的时候用setNeedDisplay即可

extension MetalViewController: CALayerDelegate {
    public func display(_ layer: CALayer) {
        render()
    }
}


//纹理相关方法

extension MetalViewController {

    public static func defaultTextureByAssets(device: MTLDevice?, name: String) -> MTLTexture? {

//        guard let image = UIImage.init(named: name)?.centerInside(width: 2000, height:2000),
//              let device = device
//        else {
//            return nil
//        }


//        return try? loader.newTexture(cgImage: cgImage, options: [.textureUsage:])

        guard let image = UIImage.init(named: name)?.centerInside(width: 1024, height: 1024) else {
            return nil
        }
        return image.toMTLTexture(device: device)

    }


    public static func defaultSamplerState(device: MTLDevice) -> MTLSamplerState? {
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

