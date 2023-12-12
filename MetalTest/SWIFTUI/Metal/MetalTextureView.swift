//
// Created by YUE on 2023/1/13.
//

import Foundation
import SwiftUI
import MetalKit

struct MetalTextureView: UIViewRepresentable {

    let progress: Double

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
        mtkView.drawableSize = mtkView.frame.size
        return mtkView
    }

    func updateUIView(_ mtkView: UIViewType, context: Context) {
        mtkView.setNeedsDisplay()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(device: device)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        
        var device: MTLDevice?
        //shader name
        private let vertexShaderName = "TextureRender::shader_vertex"
        private let fragmentShaderName = "TextureRender::shader_fragment"
        //buffer
        private var vertexBuffer: MTLBuffer? = nil
        //纹理
        private var texture: MTLTexture? = nil
        private var samplerSate: MTLSamplerState? = nil
        //渲染用的
        private var renderPass: MTLRenderPassDescriptor? = nil
        private var pipeLineState: MTLRenderPipelineState? = nil
        private var commandQueue: MTLCommandQueue? = nil


        init(device: MTLDevice?) {
            super.init()
            self.device = device
            readyForRender()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

        }

        func draw(in view: MTKView) {
            render(in: view)
        }

        private func readyForRender() {
            guard let device = device else {
                return
            }
            
            //顶点数据 position和纹理的uv
            //这里之前是用的4个SIMD4，直接改成16个长度的Float数组也行。
            let vertexData: [Float] = [
                -0.9, 0.9, 0.0, 0.0,
                -0.9, -0.9, 0.0, 1.0,
                0.9, 0.9, 1.0, 0.0,
                0.9, -0.9, 1.0, 1.0,
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
            
            pipeLineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipeLineDescriptor.colorAttachments[0].rgbBlendOperation = .add;
            pipeLineDescriptor.colorAttachments[0].alphaBlendOperation = .add;
            pipeLineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha;
            pipeLineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha;
            pipeLineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha;
            pipeLineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha;
            
            //VertexDescriptor来描述顶点数据 顶点shader那边用[[ state_in ]]接收
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float4
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.attributes[0].offset = 0
            // 每组数据的步长 每4个Float数据是一组
            vertexDescriptor.layouts[0].stride = MemoryLayout.stride(ofValue: vertexData[0]) * 4

            pipeLineDescriptor.vertexDescriptor = vertexDescriptor

            pipeLineState = try? device.makeRenderPipelineState(descriptor: pipeLineDescriptor)
            

            //生成命令队列 和 命令buffer
            commandQueue = device.makeCommandQueue()

            //生成纹理
            texture = TextureManager.textTexture(text: """
                                                       ha的开发和你说
                                                       hahaha
                                                       12345678
                                                       (*&^*(&%^^&%$$%#@
                                                       阿斯顿
                                                       里的开发和你说东方i
                                                       """, device: device)
//            texture = TextureManager.defaultTextureByAssets(device: device, name: "png_2023")
            //纹理采样
            samplerSate = TextureManager.defaultSamplerState(device: device)
        }

        private func render(in view: MTKView) {
            //drawable和renderPassDescriptor要用MTKView的
            guard
                   let texture = texture,
                   let samplerSate = samplerSate,
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
            //设置顶点buffer
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            //设置0号纹理
            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.setFragmentSamplerState(samplerSate, index: 0)
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
