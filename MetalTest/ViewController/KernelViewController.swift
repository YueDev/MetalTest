//
// Created by YUE on 2022/11/18.
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

//用计算函数来处理转场，然后绘制到屏幕上
class KernelViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private let vertexShaderName = "TransitionSimple::simple_vertex_render"
    private let fragmentShaderName = "TransitionSimple::simple_fragment_render"

    private lazy var metalLayer = {
        CAMetalLayer()
    }()

    private lazy var device = {
        MTLCreateSystemDefaultDevice()
    }()

    //顶点buffer 坐标和fragment的uv
    private var vertexBuffer: MTLBuffer? = nil
    //顶点的scale 用于给图形正确比例
    private var scaleBuffer: MTLBuffer? = nil
    //fragment的progress
    private var progressBuffer: MTLBuffer? = nil
    //fragment的图片比例
    private var ratioBuffer: MTLBuffer? = nil

    //渲染用的
    private var renderPass: MTLRenderPassDescriptor? = nil
    private var pipeLineState: MTLRenderPipelineState? = nil
    private var commandQueue: MTLCommandQueue? = nil

    //图片纹理
    private var texture1: MTLTexture? = nil
    private var texture2: MTLTexture? = nil
    private var samplerState: MTLSamplerState? = nil
    //用于计算的纹理
    private var computeTexture: MTLTexture? = nil

    //计算着色器相关
    private var kernelShaderName = "simple_mix_kernel"
    private var kernelPipeLineState: MTLComputePipelineState? = nil

    //播放动画
    private var progress: Float = 0.0
    var animator: CADisplayLink? = nil

    private lazy var slider = {
        UISlider()
    }()

    //比例按钮
    private lazy var button16_9 = {
        UIButton.init(type: .roundedRect)
    }()

    private lazy var button9_16 = {
        UIButton.init(type: .roundedRect)
    }()

    private lazy var button1_1 = {
        UIButton.init(type: .roundedRect)
    }()


    func setShaderName(_ title: String, _ kernelShaderName: String) {
        guard !kernelShaderName.isEmpty else {
            return
        }
        self.kernelShaderName = kernelShaderName
        self.title = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true

        view.layer.addSublayer(metalLayer)

        //右上角的播放按钮
        let barButton = UIBarButtonItem.init(title: "Play")
        barButton.rx.tap.subscribe { [weak self] event in
                self?.play()
            }
            .disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = barButton
        //slider
        slider.rx.value.subscribe { [weak self] in
                //给slider设置value
                self?.finishPlay()
                self?.updateProgress($0)
                self?.refreshMetal()
            }
            .disposed(by: disposeBag)

        view.addSubview(slider)

        //ratio button
        button1_1.setTitle("1 : 1", for: .normal)
        button1_1.sizeToFit()
        button1_1.rx.tap.subscribe { [weak self] event in
            self?.changePicScale(1, 1)
        }.disposed(by: disposeBag)
        view.addSubview(button1_1)

        button16_9.setTitle("16 : 9", for: .normal)
        button16_9.sizeToFit()
        button16_9.rx.tap.subscribe { [weak self] event in
            self?.changePicScale(16, 9)
        }.disposed(by: disposeBag)
        view.addSubview(button16_9)

        button9_16.setTitle("9 : 16", for: .normal)
        button9_16.sizeToFit()
        button9_16.rx.tap.subscribe { [weak self] event in
            self?.changePicScale(9, 16)
        }.disposed(by: disposeBag)
        view.addSubview(button9_16)

        do {
            try readyForRender()
        } catch {
            return
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        metalLayer.frame = view.layer.frame
        changePicScale(1.0, 1.0)

        slider.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.left.equalTo(view.safeAreaLayoutGuide).offset(32)
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-32)
        }

        button1_1.snp.makeConstraints { make in
            make.left.equalTo(slider)
            make.bottom.equalTo(slider.snp.top).offset(-16)
        }

        button9_16.snp.makeConstraints { make in
            make.right.equalTo(slider)
            make.bottom.equalTo(button1_1)
        }

        button16_9.snp.makeConstraints { make in
            make.centerY.equalTo(button1_1)
            make.left.equalTo(button1_1.snp.right)
            make.right.equalTo(button9_16.snp.left)
        }

    }





    //渲染准备

    private func readyForRender() throws {

        guard let device = device else {
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

        //顶点坐标Buffer
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        //顶点缩放，这里没使用matrix，直接算的图片和layer的比例，传给顶点, 这里不是数组的话，必须加上&
        var vertexScaleData = SIMD2<Float>(1.0, 1.0)
        scaleBuffer = device.makeBuffer(bytes: &vertexScaleData, length: MemoryLayout.stride(ofValue: vertexScaleData), options: [])
        //转场进度buffer
        var progressData: Float = 0
        progressBuffer = device.makeBuffer(bytes: &progressData, length: MemoryLayout.stride(ofValue: progressData), options: [])
        //图片比例buffer
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
        let vertexDescriptor = MTLVertexDescriptor()

        //用MTLVertexDescriptor来描述顶点数据 顶点shader那边用[[ state_in ]]接收
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
        //clear color
        let bgColor = TextureManager.getRandomBgColor()
        renderPass?.colorAttachments[0].loadAction = .clear
        renderPass?.colorAttachments[0].clearColor = MTLClearColorMake(bgColor.0, bgColor.1, bgColor.2, bgColor.3)

        //各种纹理
        texture1 = TextureManager.defaultTextureByAssets(device: device, name: "test1")
        texture2 = TextureManager.defaultTextureByAssets(device: device, name: "test2")
        samplerState = TextureManager.defaultSamplerState(device: device)

        computeTexture = TextureManager.newTextureForKernel(device: device)

        //初始化平行计算
        try readyForKernel()

    }

    //准备平行计算

    private func readyForKernel() throws {
        guard let kernelLibrary = device?.makeDefaultLibrary() else {
            return
        }
        guard let program = kernelLibrary.makeFunction(name: kernelShaderName) else {
            return
        }
        kernelPipeLineState = try device?.makeComputePipelineState(function: program)

    }


    //渲染管线　

    private func render() {

        guard let texture1 = texture1,
              let texture2 = texture2,
              let samplerState = samplerState,
              let computeTexture = computeTexture
        else {
            return
        }

        guard let pipeLineState = pipeLineState,
              let renderPass = renderPass
        else {
            return
        }

        guard let drawable = metalLayer.nextDrawable() else {
            return
        }

        //render pass设置的渲染纹理
        renderPass.colorAttachments[0].texture = drawable.texture

        //生成command buffer 这里放到渲染外初始化不行
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            return
        }

        //生成command encoder
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
            return
        }

        //与opengl的渲染到framebuffer上类似
        //先通过平行计算把两张图片的转场绘制到到纹理上
        //再把这个输出纹理渲染到metal layer上
        renderKernel(texture1, texture2, samplerState, computeTexture)

        //renderEncoder开始，设置pipeLineState
        renderEncoder.setRenderPipelineState(pipeLineState)

        //发送各种buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(scaleBuffer, offset: 0, index: 1)

        //纹理
        renderEncoder.setFragmentTexture(computeTexture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)

        //绘制三角形，1个
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        //renderEncoder结束
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    //计算函数的渲染

    private func renderKernel(
           _ inTexture1: MTLTexture,
           _ inTexture2: MTLTexture,
           _ samplerState: MTLSamplerState,
           _ outTexture: MTLTexture
    ) {

        guard let kernelPipeLineState = kernelPipeLineState else {
            return
        }
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            return
        }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        computeEncoder.setComputePipelineState(kernelPipeLineState)

        computeEncoder.setBuffer(progressBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(ratioBuffer, offset: 0, index: 1)

        computeEncoder.setTexture(inTexture1, index: 0)
        computeEncoder.setTexture(inTexture2, index: 1)
        computeEncoder.setTexture(outTexture, index: 2)
        computeEncoder.setSamplerState(samplerState, index: 0)

        //以下是平行计算的线程组
        // threadExecutionWidth: 为了实现最高效的执行，线程组大小应该是threadExecutionWidth 的倍数。
        // 6s手机上这个值是32
        let width: Int = kernelPipeLineState.threadExecutionWidth
        // maxTotalThreadsPerThreadgroup: 每个计算线程组最大可以包含的线程总数。
        let height: Int = kernelPipeLineState.maxTotalThreadsPerThreadgroup / width
        let threadsPerThreadgroup: MTLSize = MTLSizeMake(width, height, 1)


        let threadgroupsPerGrid: MTLSize = MTLSize(width: (outTexture.width + width - 1) / width,
               height: (outTexture.height + height - 1) / height,
               depth: 1)

        //平行计算是一个grid包含若干group，一个group包含若干thread，thread是最小单位，
        //用系统默认的maxTotalThreadsPerThreadgroup得到一个宽和高w h
        //这个w h代表系统一组group可以计算w * h 次
        //threadgroupsPerGrid代表一个gird 有多少组group可以同时进行。
        //放到纹理上来说，保证threadgroupsPerGrid * threadsPerThreadgroup 要等于纹理，或者刚大于纹理的长*宽最好
        computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()

        commandBuffer.commit()
    }

    //更改比例
    private func changePicScale(_ w: Float, _ h: Float) {
        let picScale = w / h

        //计算图片的缩放
        let w = Float(metalLayer.frame.width)
        let h = Float(metalLayer.frame.height)
        var scaleW: Float = 1.0
        var scaleH: Float = 1.0

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
        refreshMetal()
    }

    //更新顶点缩放 顶点用

    private func updateScale(_ scaleX: Float, _ scaleY: Float) {
        guard let ptr = scaleBuffer?.contents().bindMemory(to: SIMD2<Float>.self, capacity: 1) else {
            return
        }
        ptr.pointee = SIMD2<Float>(scaleX, scaleY)
    }


    //更新图片比例 片段用
    private func updateRatio(_ ratio: Float) {
        guard let ptr = ratioBuffer?.contents().bindMemory(to: Float.self, capacity: 1) else {
            return
        }
        ptr.pointee = ratio
    }


    //更新进度

    private func updateProgress(_ value: Float) {
        guard let ptr = progressBuffer?.contents().bindMemory(to: Float.self, capacity: 1) else {
            return
        }
        ptr.pointee = value
    }

    //刷新metal 渲染一次
    private func refreshMetal() {
        render()
    }


}






//动画相关
extension KernelViewController {

    private func play() {
        if animator != .none {
            animator?.invalidate()
            animator = .none
        }
        progress = 0.0
        animator = CADisplayLink(target: self, selector: #selector(loop))
        if #available(iOS 15.0, *) {
            animator?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, __preferred:120)
        }
        animator?.add(to: .main, forMode: .default)
    }

    private func finishPlay() {
        if animator != .none {
            animator?.invalidate()
            animator = .none
        }
    }

    @objc func loop() {
        autoreleasepool {
            progress += 0.01
            if progress >= 1.0 {
                updateProgress(1.0)
                slider.value = 1.0
                refreshMetal()
                finishPlay()
                return
            }
            updateProgress(progress)
            slider.value = progress
            refreshMetal()
        }
    }
}


