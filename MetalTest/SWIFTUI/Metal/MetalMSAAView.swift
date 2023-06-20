//
//  MetalMSAAView.swift
//  MetalTest
//
//  Created by YUE on 2023/6/20.
//
//  离屏的MSAA渲染 这里可以看出 简单的设置samplecount对离屏那一块是没有效果的
//  需要一个方法，将离屏渠道直接进行msaa渲染
//
//

import Foundation
import SwiftUI
import MetalKit

struct MetalMSAAView: UIViewRepresentable {
    
    let progress:Double
    
    typealias UIViewType = MTKView
    
    let device = {
        MTLCreateSystemDefaultDevice()
    }()
    
    func makeUIView(context: Context) -> UIViewType {
        let mtkView = MTKView()
        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.backgroundColor = .red
        mtkView.enableSetNeedsDisplay = true
        //msaa later
//        mtkView.sampleCount = 4
        mtkView.drawableSize = mtkView.frame.size
        return mtkView
    }
    
    func updateUIView(_ mtkView: UIViewType, context: Context) {
        let rotate = Float(progress * 90) - 45.0
        context.coordinator.changeRotate(rotate)
        mtkView.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(device: device)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        
        var device: MTLDevice?
        //渲染的着色器
        private let vShader = "SimpleShaderRender::normal_vertex"
        private let fShader = "SimpleShaderRender::normal_fragment"
        //离屏的着色器
        private let offscreenVShader = "SimpleShaderRender::matrix_vertex"
        private let offscreenFShader = "SimpleShaderRender::matrix_fragment"
        
        //buffer
        private var vertexBuffer: MTLBuffer? = nil
        private var offscreenVertexBuffer: MTLBuffer? = nil
        
        //mvp matrix
        private var modelMatrix = matrix_float4x4.init(1.0)
        private var viewMatrix = matrix_float4x4.init(1.0)
        private var projectionMatrix  = matrix_float4x4.init(1.0)
        
        //纹理
        private var samplerState: MTLSamplerState? = nil
        private var texture: MTLTexture? = nil
        private var dstTexture: MTLTexture? = nil
        private var msaaTexture: MTLTexture? = nil
        
        //渲染管线
        private var pipeLineState: MTLRenderPipelineState? = nil
        
        private var offscreenPipeLineState: MTLRenderPipelineState? = nil
        private var offscreenRenderPass: MTLRenderPassDescriptor? = nil
        
                
        //公用
        private var commandQueue: MTLCommandQueue? = nil
        
        init(device: MTLDevice?) {
            super.init()
            self.device = device
            readyForOffscreen()
            readyForRender()
            
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            guard size.width > 0 && size.height > 0 else {
                return
            }
            
//            let scale = Float(size.width) / Float(size.height)
            //这里是离屏窗口的比例，按照1：1来
            let scale = Float(1.0)
            let fovy:Float = 45.0
            let f = 1.0 / tan(fovy * (Float)(Double.pi / 360));
            viewMatrix = matrix_float4x4.init(eyeX: 0, eyeY: 0, eyeZ: f,
                                              centerX: 0, centerY: 0, centerZ: 0,
                                              upX: 0, upY: 1, upZ: 0)
            //projecttion
            projectionMatrix = matrix_float4x4.init(fovy: fovy, aspect: scale, zNear: 0.0, zFar: 100.0)
            view.setNeedsDisplay()
        }
        
        
        func draw(in view: MTKView) {
            renderOffscreen(in: view)
            render(in: view)
        }
        
        //更新角度
        func changeRotate(_ rotate: Float) {
            modelMatrix = .init(1.0)
            modelMatrix = modelMatrix.scaledBy(x: 0.9, y: 0.9, z: 1.0)
            modelMatrix = modelMatrix.rotatedBy(rotationAngle: rotate, x: 0.0, y: 0.0, z: 1.0)
        }
        
        //准备离屏
        private func readyForOffscreen() {
            guard let device = device else {
                return
            }
            
            //生成命令队列 和 命令buffer
            commandQueue = device.makeCommandQueue()
            
            //纹理
            texture = TextureManager.defaultTextureByAssets(device: device, name: "landscape")
            dstTexture = TextureManager.emptyTexture(device: device)
            msaaTexture = TextureManager.emptyTexture(device: device, useMSAA: true)

            samplerState = TextureManager.defaultSamplerState(device: device)
            
            
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
            
            let vertexProgram = defaultLibrary.makeFunction(name: offscreenVShader)
            let fragmentProgram = defaultLibrary.makeFunction(name: offscreenFShader)
            
            //设置pipeLineDescriptor 生成pipeLineState
            let pipeLineDescriptor = MTLRenderPipelineDescriptor()
            pipeLineDescriptor.vertexFunction = vertexProgram
            pipeLineDescriptor.fragmentFunction = fragmentProgram
            
            //设置colorAttachments[0]，主要是设置像素格式 这里要和目标纹理一直
            pipeLineDescriptor.rasterSampleCount = 4 // 设置采样次数
            pipeLineDescriptor.colorAttachments[0].pixelFormat = msaaTexture?.pixelFormat ?? .bgra8Unorm
            
            //顶点的描述
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float4
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.attributes[0].offset = 0
            // 每组数据的步长 每4个Float数据是一组
            vertexDescriptor.layouts[0].stride = MemoryLayout.stride(ofValue: vertexData[0]) * 4
            // 把创建好的vertexDescriptor 传给pipeLineDescriptor
            pipeLineDescriptor.vertexDescriptor = vertexDescriptor
            //生成 pipeLineState
            offscreenPipeLineState = try? device.makeRenderPipelineState(descriptor: pipeLineDescriptor)
            
            
            //离屏的RenderPassDescriptor， 渲染的直接拿view.currentRenderPassDescriptor即可
            offscreenRenderPass = MTLRenderPassDescriptor()
            offscreenRenderPass?.colorAttachments[0].loadAction = .clear
            offscreenRenderPass?.colorAttachments[0].clearColor = .init(red: 0.78, green: 0.85, blue: 0.82, alpha: 1.0)
            offscreenRenderPass?.colorAttachments[0].texture = msaaTexture
            //multisampleResolve表示将多重纹理的数据存到resolveTexture
            //storeAndMultisampleResolve表示把多重纹理的数据保存到内存中，并且还会放到resolveTexture中
            offscreenRenderPass?.colorAttachments[0].storeAction = .multisampleResolve
            offscreenRenderPass?.colorAttachments[0].resolveTexture = dstTexture
            
        }
        
        
        //准备渲染
        private func readyForRender() {
            guard let device = device else {
                return
            }
            
            //顶点数据 position和纹理的uv
            let vertexData: [Float] = [
                -0.8, 0.8, 0.0, 0.0,
                 -0.8, -0.8, 0.0, 1.0,
                 0.8, 0.8, 1.0, 0.0,
                 0.8, -0.8, 1.0, 1.0,
            ]
            
            let vertexDataSize = MemoryLayout.stride(ofValue: vertexData[0]) * vertexData.count
            vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexDataSize, options: [])
            
            //生成shader program
            guard let defaultLibrary = device.makeDefaultLibrary() else {
                return
            }
            
            let vertexProgram = defaultLibrary.makeFunction(name: vShader)
            let fragmentProgram = defaultLibrary.makeFunction(name: fShader)
            
            //设置pipeLineDescriptor 生成pipeLineState
            let pipeLineDescriptor = MTLRenderPipelineDescriptor()
            pipeLineDescriptor.vertexFunction = vertexProgram
            pipeLineDescriptor.fragmentFunction = fragmentProgram
            //这里要设置像素格式
            pipeLineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            //顶点的描述
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float4
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.attributes[0].offset = 0
            // 每组数据的步长 每4个Float数据是一组
            vertexDescriptor.layouts[0].stride = MemoryLayout.stride(ofValue: vertexData[0]) * 4
            // 把创建好的vertexDescriptor 传给pipeLineDescriptor
            pipeLineDescriptor.vertexDescriptor = vertexDescriptor
//            //msaa采样数
//            pipeLineDescriptor.rasterSampleCount = 4
            //生成 pipeLineState
            pipeLineState = try? device.makeRenderPipelineState(descriptor: pipeLineDescriptor)
        }
        
        //离屏渲染
        private func renderOffscreen(in view: MTKView) {
            //drawable和renderPassDescriptor要用MTKView的
            guard
                let offscreenRenderPass = offscreenRenderPass,
                let offscreenPipeLineState = offscreenPipeLineState,
                let commandBuffer = commandQueue?.makeCommandBuffer()
            else {
                return
            }
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: offscreenRenderPass) else {
                return
            }

             renderEncoder.setRenderPipelineState(offscreenPipeLineState)
            
            //发送顶点buffer
            renderEncoder.setVertexBuffer(offscreenVertexBuffer, offset: 0, index: 0)
            //发送mvp
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout.stride(ofValue: modelMatrix), index: 1)
            renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout.stride(ofValue: viewMatrix), index: 2)
            renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout.stride(ofValue: projectionMatrix), index: 3)
            
            //设置纹理
            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
            //绘制三角形，1个
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            //endEncoding 结束渲染编码
            renderEncoder.endEncoding()
            commandBuffer.commit()

        }
        
        //渲染
        private func render(in view: MTKView) {
            //drawable和renderPassDescriptor要用MTKView的
            guard
                let drawable = view.currentDrawable,
                let renderPass = view.currentRenderPassDescriptor,
                let pipeLineState = pipeLineState,
                let commandBuffer = commandQueue?.makeCommandBuffer()
            else {
                return
            }
            
            renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.4, 0.3, 1.0)
            renderPass.colorAttachments[0].loadAction = .clear
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
                return
            }
            renderEncoder.setRenderPipelineState(pipeLineState)
            
            //发送顶点buffer
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            //设置纹理
            renderEncoder.setFragmentTexture(dstTexture, index: 0)
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
            
            //绘制三角形，1个
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            //endEncoding 结束渲染编码
            renderEncoder.endEncoding()
            
            //commandBuffer 设置drawable并提交
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

