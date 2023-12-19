//
//  MetalFoldTransView.swift
//  MetalTest
//
//  android折叠的view
//

import Foundation
import SwiftUI
import MetalKit

struct MetalFoldTransView: UIViewRepresentable {
    
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
        
        private var progress: Float = 0.0
        
        var device: MTLDevice?
        private let vertexShaderName = "SimpleShaderRender::matrix_vertex"
        private let fragmentShaderName = "SimpleShaderRender::matrix_fragment"
        
        //buffer
        private var vertexBuffer1: MTLBuffer? = nil //底部1
        private var vertexBuffer2: MTLBuffer? = nil //底部2
        private var vertexBuffer3: MTLBuffer? = nil //折叠1
        private var vertexBuffer4: MTLBuffer? = nil //折叠2

        //mvp matrix
        private var modelMatrix = matrix_float4x4.init(1.0)
        private var viewMatrix = matrix_float4x4.init(1.0)
        private var projectionMatrix  = matrix_float4x4.init(1.0)
        
        //纹理
        private var samplerState: MTLSamplerState? = nil
        private var texture1: MTLTexture? = nil
        private var texture2: MTLTexture? = nil

        
        //渲染
        private var renderPass: MTLRenderPassDescriptor? = nil
        private var pipeLineState: MTLRenderPipelineState? = nil
        private var commandQueue: MTLCommandQueue? = nil
        
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
                                              centerX: 0, centerY: 0, centerZ: 0.0,
                                              upX: 0, upY: 1, upZ: 0)
            //projecttion
            projectionMatrix = matrix_float4x4.init(fovy: fovy, aspect: scale, zNear: 0.0, zFar: 100.0)
            
            modelMatrix = .init(1.0)
            
            view.setNeedsDisplay()
        }
        
        
        func draw(in view: MTKView) {
            render(in: view)
        }
        
        
        func changeProgress(_ progress: Float) {
            self.progress = progress
        }
        
        
        
        private func readyForRender() {
            guard let device = device else {
                return
            }
            
            // 顶点数据 position和纹理的uv
            
            // 画三个正方形
            // 前两个正方形组成底 一个显示图片左边，一个显示图片右边
            // 第三个正方型进行旋转
//            let vertexData: [Float] = [
//                -1.0, 1.0, 0.0, 0.0,  //左上
//                -1.0, -1.0, 0.0, 1.0, //左下
//                0.0, 1.0, 0.5, 0.0,   //右上
//                0.0, -1.0, 0.5, 1.0,  //右下
//                 
//                0.0, 1.0, 0.5, 0.0,   //左上
//                0.0, -1.0, 0.5, 1.0,  //左下
//                1.0, 1.0, 1.0, 0.0,   //右上
//                1.0, -1.0, 1.0, 1.0,  //右下
//                 
//                 0.0, 1.0, 0.5, 0.0,   //左上
//                 0.0, -1.0, 0.5, 1.0,  //左下
//                 1.0, 1.0, 1.0, 0.0,   //右上
//                 1.0, -1.0, 1.0, 1.0,  //右下
//            ]
//            
//            let vertexDataSize = MemoryLayout.stride(ofValue: vertexData[0]) * vertexData.count
//            vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexDataSize, options: [])
            
            //初始化4个buffer
            let vertexData1: [Float] = [
                -1.0, 1.0, 0.0, 0.0,  //左上
                -1.0, -1.0, 0.0, 1.0, //左下
                0.0, 1.0, 0.5, 0.0,   //右上
                0.0, -1.0, 0.5, 1.0,  //右下
            ]
            let vertexDataSize1 = MemoryLayout.stride(ofValue: vertexData1[0]) * vertexData1.count
            vertexBuffer1 = device.makeBuffer(bytes: vertexData1, length: vertexDataSize1, options: [])
            
            
            let vertexData2: [Float] = [
                0.0, 1.0, 0.5, 0.0,   //左上
                0.0, -1.0, 0.5, 1.0,  //左下
                1.0, 1.0, 1.0, 0.0,   //右上
                1.0, -1.0, 1.0, 1.0,  //右下
            ]
            let vertexDataSize2 = MemoryLayout.stride(ofValue: vertexData2[0]) * vertexData2.count
            vertexBuffer2 = device.makeBuffer(bytes: vertexData2, length: vertexDataSize2, options: [])
            
            let vertexData3: [Float] = [
                0.0, 1.0, 0.5, 0.0,   //左上
                0.0, -1.0, 0.5, 1.0,  //左下
                1.0, 1.0, 1.0, 0.0,   //右上
                1.0, -1.0, 1.0, 1.0,  //右下
            ]
            let vertexDataSize3 = MemoryLayout.stride(ofValue: vertexData3[0]) * vertexData3.count
            vertexBuffer3 = device.makeBuffer(bytes: vertexData3, length: vertexDataSize3, options: [])
            
            let vertexData4: [Float] = [
                -1.0, 1.0, 0.0, 0.0,  //左上
                -1.0, -1.0, 0.0, 1.0, //左下
                0.0, 1.0, 0.5, 0.0,   //右上
                0.0, -1.0, 0.5, 1.0,  //右下
            ]
            let vertexDataSize4 = MemoryLayout.stride(ofValue: vertexData4[0]) * vertexData4.count
            vertexBuffer4 = device.makeBuffer(bytes: vertexData4, length: vertexDataSize4, options: [])
            
            
            
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
            vertexDescriptor.layouts[0].stride = MemoryLayout.stride(ofValue: vertexData1[0]) * 4
            // 把创建好的vertexDescriptor 传给pipeLineDescriptor
            pipeLineDescriptor.vertexDescriptor = vertexDescriptor
            //msaa采样数
//            pipeLineDescriptor.rasterSampleCount = 4
            //生成 pipeLineState
            pipeLineState = try? device.makeRenderPipelineState(descriptor: pipeLineDescriptor)
            
            //生成命令队列 和 命令buffer
            commandQueue = device.makeCommandQueue()
            
            //纹理
            let textureName1 = TextureManager.getPeopleTextureName()
            texture1 = TextureManager.defaultTextureByAssets(device: device, name: textureName1)
            let textureName2 = TextureManager.getPeopleTextureName()
            texture2 = TextureManager.defaultTextureByAssets(device: device, name: textureName2)
            
            samplerState = TextureManager.defaultSamplerState(device: device)

        }
        
        private func render(in view: MTKView) {
            //drawable和renderPassDescriptor要用MTKView的
            guard
                let drawable = view.currentDrawable,
                let renderPass = view.currentRenderPassDescriptor,
                let pipeLineState = pipeLineState,
                let texture1 = texture1,
                let texture2 = texture2,
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
            
            renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout.stride(ofValue: viewMatrix), index: 2)
            renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout.stride(ofValue: projectionMatrix), index: 3)
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)

            
            //绘制底部的两个三角形
            modelMatrix = .init(1.0)
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout.stride(ofValue: modelMatrix), index: 1)
            
            renderEncoder.setFragmentTexture(texture1, index: 0)
            renderEncoder.setVertexBuffer(vertexBuffer1, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)

            renderEncoder.setFragmentTexture(texture2, index: 0)
            renderEncoder.setVertexBuffer(vertexBuffer2, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)


            
            //绘制旋转的三角形
            //0度旋转到180度
            
            if progress < 0.5 {
                //从0翻转到-90
                modelMatrix = .init(1.0)
                modelMatrix = modelMatrix.rotatedBy(rotationAngle: progress * -180.0, x: 0.0, y: 1.0, z: 0.0)
                renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout.stride(ofValue: modelMatrix), index: 1)
                renderEncoder.setFragmentTexture(texture1, index: 0)
                renderEncoder.setVertexBuffer(vertexBuffer3, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            } else {
                //从90翻转到0
                modelMatrix = .init(1.0)
                modelMatrix = modelMatrix.rotatedBy(rotationAngle: 180.0 - progress * 180.0, x: 0.0, y: 1.0, z: 0.0)
                renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout.stride(ofValue: modelMatrix), index: 1)
                renderEncoder.setFragmentTexture(texture2, index: 0)
                renderEncoder.setVertexBuffer(vertexBuffer4, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            }

            
            //endEncoding 结束渲染编码
            renderEncoder.endEncoding()
            
            //commandBuffer 设置drawable并提交
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

