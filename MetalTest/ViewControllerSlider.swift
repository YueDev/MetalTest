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
import SnapKit

import simd


class ViewControllerSlider: UIViewController {

    let disposeBag = DisposeBag()

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


    override func viewDidLayoutSubviews() {

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
            VertexModel(positionAndUV: SIMD4<Float>(-0.9, 0.9, 0.0, 0.0), color1: SIMD4<Float>(0.8, 0.8, 0.2, 1.0), color2: SIMD4<Float>(0.7, 0.0, 0.0, 0.0)),
            VertexModel(positionAndUV: SIMD4<Float>(-0.9, -0.9, 0.0, 1.0), color1: SIMD4<Float>(0.8, 0.8, 0.2, 1.0), color2: SIMD4<Float>(0.0, 0.7, 0.0, 0.0)),
            VertexModel(positionAndUV: SIMD4<Float>(0.9, 0.9, 1.0, 0.0), color1: SIMD4<Float>(0.8, 0.8, 0.2, 1.0), color2: SIMD4<Float>(0.0, 0.0, 0.7, 0.0)),
            VertexModel(positionAndUV: SIMD4<Float>(0.9, -0.9, 1.0, 1.0), color1: SIMD4<Float>(0.8, 0.8, 0.2, 1.0), color2: SIMD4<Float>(0.0, 0.0, 0.0, 0.0)),
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

        let vertexProgram = defaultLibrary.makeFunction(name: "simple_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "simple_fragment_slide")

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
        renderPass?.colorAttachments[0].clearColor = MTLClearColorMake(0.4, 0.7, 0.4, 1.0)
        //生成纹理 采样器
        texture1 = ViewController.defaultTextureByAssets(device: device, name: "test1")
        texture2 = ViewController.defaultTextureByAssets(device: device, name: "test2")
        samplerState = ViewController.defaultSamplerState(device: device)
    }




    //更新图片比例

    private func updateScale(_ scaleX: Float, _ scaleY: Float) {
        guard let vertexBufferPtr = vertexScaleBuffer?.contents().bindMemory(to: SIMD2<Float>.self, capacity: 1) else {
            return
        }
        print("\(scaleX) * \(scaleY)")
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

extension ViewControllerSlider: CALayerDelegate {
    public func display(_ layer: CALayer) {
        render()
    }
}

