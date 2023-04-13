//
//  MetalRotateBlurView.swift
//  MetalTest
//
//  Created by YUE on 2023/4/13.
//

import Foundation
import SwiftUI
import MetalKit
import MetalPerformanceShaders

struct MetalRotateBlurView: UIViewRepresentable {
    
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
        context.coordinator.changeProgress(Float(progress))
        mtkView.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(device: device)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        
        var device: MTLDevice?
        private let vertexShaderName = "SimpleShaderRender::matrix_vertex"
        private let fragmentShaderName = "SimpleShaderRender::rotate_blur_fragment"
        
        //buffer
        private var vertexBuffer: MTLBuffer? = nil
        
        // mvp matrix
        private var modelMatrix = matrix_float4x4.init(1.0)
        private var viewMatrix = matrix_float4x4.init(1.0)
        private var projectionMatrix  = matrix_float4x4.init(1.0)
        
        // 纹理
        private var samplerState: MTLSamplerState? = nil
        private var texture: MTLTexture? = nil
        
        private var blurSize: Float = 0.0
        
        // 渲染
        private var renderPass: MTLRenderPassDescriptor? = nil
        private var pipeLineState: MTLRenderPipelineState? = nil
        private var commandQueue: MTLCommandQueue? = nil
        
        //强制图片比例，测试旋转的比例是痘正确
        private var ratio: Float = 2.0 / 3.0
        
        init(device: MTLDevice?) {
            super.init()
            self.device = device
            readyForRender()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            guard size.width > 0 && size.height > 0 else {
                return
            }
            
            let scale = Float(size.width) / Float(size.height)
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
            
            render(in: view)
        }
        
        //更新角度
        func changeProgress(_ progress: Float) {
            blurSize = progress * 2
        }
        
        private func readyForRender() {
            guard let device = device else {
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
            //msaa采样数
//            pipeLineDescriptor.rasterSampleCount = 4
            //生成 pipeLineState
            pipeLineState = try? device.makeRenderPipelineState(descriptor: pipeLineDescriptor)
            
            //生成命令队列 和 命令buffer
            commandQueue = device.makeCommandQueue()
            
            //纹理
            let textureName = TextureManager.getPeopleTextureName()
            texture = TextureManager.defaultTextureByAssets(device: device, name: textureName)
            samplerState = TextureManager.defaultSamplerState(device: device)

            modelMatrix = .init(1.0)
            modelMatrix = modelMatrix.scaledBy(x: 0.8, y: 0.8, z: 1.0)
            modelMatrix = modelMatrix.scaledBy(x: ratio, y: 1.0, z: 1.0)
        }
    
        
        private func render(in view: MTKView) {

            //drawable和renderPassDescriptor要用MTKView的
            guard
                let texture = texture,
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
            //发送mvp
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout.stride(ofValue: modelMatrix), index: 1)
            renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout.stride(ofValue: viewMatrix), index: 2)
            renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout.stride(ofValue: projectionMatrix), index: 3)
            
            //设置纹理
            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
            
            renderEncoder.setFragmentBytes(&blurSize, length: MemoryLayout.stride(ofValue: blurSize), index: 0)
            renderEncoder.setFragmentBytes(&ratio, length: MemoryLayout.stride(ofValue: ratio), index: 1)

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

