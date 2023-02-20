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

//最早的渲染vc 后来改成计算函数生成纹理，这个暂时不用了　
//     如果用的话 把首页的数改成这个
//    private let allData = [
//        //简单组
//        [
//            ("渐变", "simple_vertex", "simple_fragment_mix"),
//            ("向左滑动", "simple_vertex", "simple_fragment_slide_left"),
//            ("向右滑动", "simple_vertex", "simple_fragment_slide_right"),
//            ("向上滑动", "simple_vertex", "simple_fragment_slide_up"),
//            ("向下滑动", "simple_vertex", "simple_fragment_slide_down"),
//            ("向左覆盖", "simple_vertex", "simple_fragment_cover_left"),
//            ("向右覆盖", "simple_vertex", "simple_fragment_cover_right"),
//            ("向上覆盖", "simple_vertex", "simple_fragment_cover_up"),
//            ("向下覆盖", "simple_vertex", "simple_fragment_cover_down"),
//            ("心形", "simple_vertex", "simple_fragment_heart_out"),
//        ],
//    ]


//顶点的结构

//由于用的是MTLVertexDescriptor描述顶点数据，因此不需要定义oc结构给metal做桥接。
//metal的着色器里有对应的结构 VertexIn
//需要倒入simd　floatX被遗弃，提示用SIMD<FloatX>代替
//尽量别用float2, 用的话往后放有对齐 float3和float4没有


class MetalViewController: UIViewController {



    var animator: CADisplayLink? = nil

    private var vertexShaderName = "simple_vertex"
    private var fragmentShaderName = "simple_fragment_mix"

    private let disposeBag = DisposeBag()

    private lazy var slider = {
        UISlider()
    }()

    private lazy var playButton = {
        UIButton()
    }()

    private lazy var device = {
        MTLCreateSystemDefaultDevice()
    }()

    private lazy var metalLayer = {
        CAMetalLayer()
    }()


    //顶点buffer 坐标和fragment的uv
    private var vertexBuffer: MTLBuffer? = nil
    //fragment的progress
    private var fragmentBuffer: MTLBuffer? = nil
    //顶点的scale 用于给图形正确比例
    private var scaleBuffer: MTLBuffer? = nil
    
    //图片的比例 fragment用
    private var ratioBuffer: MTLBuffer? = nil


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
                self?.finishPlay()
                self?.updateProgress($0)
            }
            .disposed(by: disposeBag)

        view.addSubview(slider)

        playButton.setTitle("Play", for: .normal)
        playButton.sizeToFit()
        playButton.rx.tap.subscribe { [weak self] event in
                self?.play()
            }
            .disposed(by: disposeBag)

        view.addSubview(playButton)

        do {
            try readyForRender()
        } catch {
            print(error)
            return
        }
    }


    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        playButton.snp.makeConstraints { make in
            make.bottom.equalTo(slider.snp.top).offset(-16)
            make.left.equalTo(slider)
        }

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
        //更新顶点的缩放
        updateScale(scaleW, scaleH)
        // 更新图片的比例
        updateRatio(picScale)
    }


    //渲染之前的准备

    private func readyForRender() throws {

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
        scaleBuffer = device.makeBuffer(bytes: &vertexScaleData, length: MemoryLayout.stride(ofValue: vertexScaleData), options: [])


        //生成fragment buffer 这里和opengl的uniform差不多，给fragment传随时刷新的数据
        var fragmentData: Float = 0
        //这里不是数组的话，必须加上&
        fragmentBuffer = device.makeBuffer(bytes: &fragmentData, length: MemoryLayout.stride(ofValue: fragmentData), options: [])

        var ratio = vertexScaleData.x / vertexScaleData.y
        ratioBuffer = device.makeBuffer(bytes: &ratio, length: MemoryLayout.stride(ofValue: ratio), options: [])


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

        let bgColor = TextureManager.getRandomBgColor()

        renderPass?.colorAttachments[0].clearColor = MTLClearColorMake(bgColor.0, bgColor.1, bgColor.2, bgColor.3)
        //生成纹理 采样器
        texture1 = TextureManager.defaultTextureByAssets(device: device, name: "test1")
        texture2 = TextureManager.defaultTextureByAssets(device: device, name: "test2")
        samplerState = TextureManager.defaultSamplerState(device: device)
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
        //发送vertex的uniform scale
        renderEncoder.setVertexBuffer(scaleBuffer, offset: 0, index: 1)
        //发送fragment的uniform， 也是通过buffer实现的
        renderEncoder.setFragmentBuffer(fragmentBuffer, offset: 0, index: 0)
        
        renderEncoder.setFragmentBuffer(ratioBuffer, offset: 0, index: 1)

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



    //更新顶点的缩放

    private func updateScale(_ scaleX: Float, _ scaleY: Float) {
        guard let vertexBufferPtr = scaleBuffer?.contents().bindMemory(to: SIMD2<Float>.self, capacity: 1) else {
            return
        }
        vertexBufferPtr.pointee = SIMD2<Float>(scaleX, scaleY)
        metalLayer.setNeedsDisplay()
    }
    
    //更新图片的比例
    private func updateRatio(_ ratio: Float) {
        guard let ratioPtr = ratioBuffer?.contents().bindMemory(to: Float.self, capacity: 1) else {
            return
        }
        ratioPtr.pointee = ratio
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

    private func play() {
        if animator != .none {
            animator?.invalidate()
            animator = .none
        }
        progress = 0.0
        animator = CADisplayLink(target: self, selector: #selector(loop))
        animator?.add(to: .main, forMode: .default)
    }

    private func finishPlay() {
        if animator != .none {
            animator?.invalidate()
            animator = .none
        }
    }

    private var progress: Float = 0.0

    @objc func loop() {
        autoreleasepool {
            progress += 0.01
            guard progress < 1.0 else {
                finishPlay()
                return
            }
            updateProgress(progress)
        }
    }

}

//设置代理，刷新的时候用setNeedDisplay即可

extension MetalViewController: CALayerDelegate {
    public func display(_ layer: CALayer) {
        render()
    }
}

