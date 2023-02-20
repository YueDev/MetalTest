//
//  MetalOffscreenViewController.swift
//  MetalTest
//
//  Created by YUE on 2023/2/16.
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

//metal离屏渲染
//用离屏将两张贴纸纹理绘制到目标纹理（图片）上
//在用metalview把目标纹理显示到屏幕上
class MetalOffscreenViewController: UIViewController {
    
    //着色器
    //metalLayer
    private var vertexShaderName = "OffscreenShader::main_vertex"
    private var fragmentShaderName = "OffscreenShader::main_fragment"
    //离屏渲染
    private var offscreenVertexShaderName = "OffscreenShader::offscreen_vertex"
    private var offscreenFragmentShaderName = "OffscreenShader::offscreen_fragment"
    
    //buffer
    //metalLayer的顶点buffer 坐标和fragment的uv
    private var vertexBuffer: MTLBuffer? = nil
    //离屏的顶点buffer 坐标和fragment的uv
    private var offscreenVertexBuffer: MTLBuffer? = nil
    

    
    
    //纹理
    //metallayer的纹理，即目标纹理
    private var dstTexture: MTLTexture? = nil
    //贴纸纹理
    private var stickerTexture1: MTLTexture? = nil
    private var stickerTexture2: MTLTexture? = nil
    //背景纹理
    private var bgTexture:MTLTexture? = nil
    //采样器
    private var samplerState: MTLSamplerState? = nil
    //纹理的矩阵的
    private var bgModel = matrix_float4x4.init(1.0)
    private var sticker1Model = matrix_float4x4.init(1.0)
    //vp
    private var viewMatrix = matrix_float4x4.init(1.0)
    private var projectionMatrix  = matrix_float4x4.init(1.0)
    
    
    //管线
    //commandQueue共用
    private var commandQueue: MTLCommandQueue? = nil
    //metalLayer
    private var pipeLineState: MTLRenderPipelineState? = nil
    private var renderPass: MTLRenderPassDescriptor? = nil
    //离屏
    private var offscreenPipeLineState: MTLRenderPipelineState? = nil
    private var offscreenRenderPass: MTLRenderPassDescriptor? = nil

    
    private lazy var device = {
        MTLCreateSystemDefaultDevice()
    }()
    
    private lazy var metalLayer = {
        CAMetalLayer()
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.delegate = self
        
        view.layer.addSublayer(metalLayer)
        
        readyForOffscreen()
        ready()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        metalLayer.frame = view.layer.frame
        
        
        //model
        sticker1Model = .init(1.0)
        sticker1Model = sticker1Model.scaledBy(x: 0.5, y: 0.5, z: 1.0)
//        sticker1Model = sticker1Model.translatedBy(x: 0.0, y: -1.0, z: 0.0)
        sticker1Model = sticker1Model.rotatedBy(rotationAngle: 90, x: 0.0, y: 0.0, z: 0.1)
//        sticker1Model = sticker1Model.translatedBy(x: 0.0, y: 1.0, z: 0.0)
        
        //view
        let scale = Float(metalLayer.frame.width / metalLayer.frame.height)
        let fovy:Float = 45.0
        let f = 1.0 / tan(fovy * (Float)(CGFloat.pi / 360));
        viewMatrix = matrix_float4x4.init(eyeX: 0, eyeY: 0, eyeZ: f,
                                              centerX: 0, centerY: 0, centerZ: 0,
                                              upX: 0, upY: 1, upZ: 0)
        //projecttion
        projectionMatrix = matrix_float4x4.init(fovy: fovy, aspect: scale, zNear: 0.0, zFar: 100.0)
        
        
        metalLayer.setNeedsDisplay()
    }
    
    //离屏渲染的准备
    private func readyForOffscreen() {
        
        guard let device = self.device else {
            return
        }
        
        //目标纹理
        dstTexture = TextureManager.emptyTexture(device: device)
        bgTexture = TextureManager.defaultTextureByAssets(device: device, name: "test2")
        //贴纸纹理
        stickerTexture1 = TextureManager.defaultTextureByAssets(device: device, name: "sticker1")
        stickerTexture2 = TextureManager.defaultTextureByAssets(device: device, name: "sticker2")

        //纹理的采样器
        samplerState = TextureManager.defaultSamplerState(device: device)
        //生成commandQueue
        commandQueue = device.makeCommandQueue()
        
        //顶点数据 position和纹理的uv
        let vertexData: [Float] = [
            -1.0, 1.0, 0.0, 0.0,
             -1.0, -1.0, 0.0, 1.0,
             1.0, 1.0, 1.0, 0.0,
             1.0, -1.0, 1.0, 1.0,
        ]
        let vertexDataSize = MemoryLayout.stride(ofValue: vertexData[0]) * vertexData.count
        offscreenVertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexDataSize, options: [])
        
        //生成shader program
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            return
        }
        let vertexProgram = defaultLibrary.makeFunction(name: offscreenVertexShaderName)
        let fragmentProgram = defaultLibrary.makeFunction(name: offscreenFragmentShaderName)
        
        //创建pipeLineDescriptor并配置
        //设置pipeLineDescriptor的着色器函数
        let pipeLineDescriptor = MTLRenderPipelineDescriptor()
        pipeLineDescriptor.vertexFunction = vertexProgram
        pipeLineDescriptor.fragmentFunction = fragmentProgram
        //VertexDescriptor来描述顶点数据 顶点shader那边用[[ state_in ]]接收
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        // 每组数据的步长 每4个Float数据是一组
        vertexDescriptor.layouts[0].stride = MemoryLayout.stride(ofValue: vertexData[0]) * 4
        // 把创建好的vertexDescriptor 传给pipeLineDescriptor
        pipeLineDescriptor.vertexDescriptor = vertexDescriptor
        //设置colorAttachments[0]，主要是设置像素格式 这里要和目标纹理一直
        pipeLineDescriptor.colorAttachments[0].pixelFormat = dstTexture!.pixelFormat
        //混合模式 这样透明图如png就显示正常了
        pipeLineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipeLineDescriptor.colorAttachments[0].rgbBlendOperation = .add;
        pipeLineDescriptor.colorAttachments[0].alphaBlendOperation = .add;
        pipeLineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha;
        pipeLineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha;
        pipeLineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha;
        pipeLineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha;
        
        //根据pipeLineDescriptor生成pipeLineState
        offscreenPipeLineState = try? device.makeRenderPipelineState(descriptor: pipeLineDescriptor)
        
        //生成render pass 设置离屏渲染的纹理 不同于clearcolor，这里loadAction为.load
        //dst纹理由于动画会一直改变，所以应该用一个空白纹理，这里需要将背景作为一个贴纸铺满view
        offscreenRenderPass = MTLRenderPassDescriptor()
        offscreenRenderPass?.colorAttachments[0].loadAction = .clear
        offscreenRenderPass?.colorAttachments[0].texture = dstTexture
    }
    
    
    //离屏渲染
    private func renderForOffscreen() {
        guard
            let stickerTexture1 = stickerTexture1,
            let stickerTexture2 = stickerTexture2,
            let samplerState = samplerState,
            let offscreenRenderPass = offscreenRenderPass,
            let offscreenPipeLineState = offscreenPipeLineState,
            let commandBuffer = commandQueue?.makeCommandBuffer()
        else {
            return
        }
        
        //生成command encoder
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: offscreenRenderPass) else {
            return
        }
        
        //设置renderEncoder 编码渲染的内容
        //设置pipeline state
        renderEncoder.setRenderPipelineState(offscreenPipeLineState)
        //发送顶点数据  这个好像没法和opengl一样在渲染之前设置
        renderEncoder.setVertexBuffer(offscreenVertexBuffer, offset: 0, index: 0)
        
        renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout.stride(ofValue: viewMatrix), index: 2)
        renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout.stride(ofValue: projectionMatrix), index: 3)

        
        //设置纹理采样器
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        
        //绘制背景纹理
        renderEncoder.setVertexBytes(&bgModel, length: MemoryLayout.stride(ofValue: bgModel), index: 1)
        renderEncoder.setFragmentTexture(bgTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        
        //绘制第一个贴纸
        renderEncoder.setVertexBytes(&sticker1Model, length: MemoryLayout.stride(ofValue: sticker1Model), index: 1)
        renderEncoder.setFragmentTexture(stickerTexture1, index: 0)
        //绘制第一个纹理
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
//        //设置第二个纹理
//        renderEncoder.setFragmentTexture(stickerTexture2, index: 0)
//        //绘制第二个纹理
//        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        
        //endEncoding 结束渲染编码
        renderEncoder.endEncoding()
        commandBuffer.commit()
        
    }
    
    //metalLayer渲染的准备
    private func ready() {
        guard let device = self.device else {
            return
        }
        
        //顶点数据 position和纹理的uv
        let vertexData: [Float] = [
            -1.0, 1.0, 0.0, 0.0,
             -1.0, -1.0, 0.0, 1.0,
             1.0, 1.0, 1.0, 0.0,
             1.0, -1.0, 1.0, 1.0,
        ]
        
        let vertexDataSize = MemoryLayout.stride(ofValue: vertexData[0]) * vertexData.count
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexDataSize, options: [])
        
        //生成shader program
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            return
        }
        let vertexProgram = defaultLibrary.makeFunction(name: vertexShaderName)
        let fragmentProgram = defaultLibrary.makeFunction(name: fragmentShaderName)
        
        //创建pipeLineDescriptor并配置
        //设置pipeLineDescriptor的着色器函数
        let pipeLineDescriptor = MTLRenderPipelineDescriptor()
        pipeLineDescriptor.vertexFunction = vertexProgram
        pipeLineDescriptor.fragmentFunction = fragmentProgram
        //VertexDescriptor来描述顶点数据 顶点shader那边用[[ state_in ]]接收
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        // 每组数据的步长 每4个Float数据是一组
        vertexDescriptor.layouts[0].stride = MemoryLayout.stride(ofValue: vertexData[0]) * 4
        // 把创建好的vertexDescriptor 传给pipeLineDescriptor
        pipeLineDescriptor.vertexDescriptor = vertexDescriptor
        //设置colorAttachments[0]，主要是设置像素格式
        pipeLineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        //根据pipeLineDescriptor生成pipeLineState
        pipeLineState = try? device.makeRenderPipelineState(descriptor: pipeLineDescriptor)
        
        //生成render pass 可以设置color clear之类的
        renderPass = MTLRenderPassDescriptor()
        renderPass?.colorAttachments[0].loadAction = .clear
        renderPass?.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.3, 0.3, 1.0)
        
    }
    //metalLayer渲染
    private func render() {
        guard
            let dstTexture = dstTexture,
            let samplerState = samplerState,
            let drawable = metalLayer.nextDrawable(),
            let renderPass = renderPass,
            let pipeLineState = pipeLineState,
            let commandBuffer = commandQueue?.makeCommandBuffer()
        else {
            return
        }
        
        //render pass设置纹理
        renderPass.colorAttachments[0].texture = drawable.texture
        
        //生成command encoder
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
            return
        }
        
        //设置renderEncoder 编码渲染的内容
        //设置pipeline state
        renderEncoder.setRenderPipelineState(pipeLineState)
        //发送顶点数据  这个好像没法和opengl一样在渲染之前设置
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        //设置纹理和采样器
        renderEncoder.setFragmentTexture(dstTexture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        
        //绘制正方形
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        
        //endEncoding 结束渲染编码
        renderEncoder.endEncoding()
        
        //commandBuffer 设置drawable并提交
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
}


//设置代理，刷新的时候用metalLayer的setNeedDisplay即可
extension MetalOffscreenViewController: CALayerDelegate {
    public func display(_ layer: CALayer) {
        renderForOffscreen()
        render()
    }
}
