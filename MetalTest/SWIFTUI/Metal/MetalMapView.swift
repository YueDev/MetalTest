//
// Created by YUE on 2023/1/13.
//

import Foundation
import SwiftUI
import MetalKit

struct MetalMapView: UIViewRepresentable {
    
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
        mtkView.sampleCount = 4
        //        mtkView.isPaused = true
        //        mtkView.clearColor = MTLClearColor(red: 0.2, green: 0.3, blue: 0.2, alpha: 1.0)
        mtkView.drawableSize = mtkView.frame.size
        return mtkView
    }
    
    func updateUIView(_ mtkView: UIViewType, context: Context) {
        context.coordinator.changeColor(percent: progress)
        mtkView.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(device: device)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        
        var device: MTLDevice?
        
        //buffer
        private var vertexBuffer: MTLBuffer? = nil
        private var colorBuffer: MTLBuffer? = nil
        
        //渲染用的
        private var renderPass: MTLRenderPassDescriptor? = nil
        private var pipeLineState: MTLRenderPipelineState? = nil
        private var commandQueue: MTLCommandQueue? = nil
        
        //shader
        private let vertexShaderName = "SimpleShaderRender::simple_vertex"
        private let fragmentShaderName = "SimpleShaderRender::simple_fragment"
        
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
            
            //顶点数据
            let vertexData: [Float] = [
                -0.9, 0.9, 0.0,
                 -0.9, -0.9, 0.0,
                 0.9, 0.9, 0.0,
                 0.9, -0.9, 0.0
            ]
            let vertexDataSize = MemoryLayout.stride(ofValue: vertexData[0]) * vertexData.count
            vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexDataSize, options: [])
            
            //顶点对应的颜色数据
            let colorData: [Float] = [
                            0.5, 0.4, 0.3,
                            0.6, 0.5, 0.2,
                            0.2, 0.7, 0.5,
                            0.5, 0.5, 0.8,
                        ]
                        let colorSize = MemoryLayout.stride(ofValue: colorData[0]) * colorData.count
                        colorBuffer = device.makeBuffer(bytes: colorData, length: colorSize, options: [])
            
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
            
            pipeLineState = try? device.makeRenderPipelineState(descriptor: pipeLineDescriptor)
            
            //生成命令队列 和 命令buffer
            commandQueue = device.makeCommandQueue()
            
        }
        
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
            renderPass.colorAttachments[0].storeAction = .store
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
                return
            }
            
            renderEncoder.setRenderPipelineState(pipeLineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 1)
            //绘制三角形，1个
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            //endEncoding 结束渲染编码
            renderEncoder.endEncoding()
            
            //commandBuffer 设置drawable并提交
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        //更新颜色
        func changeColor(percent: Double) {
            guard let colors = colorBuffer?.contents().bindMemory(to: Float.self, capacity: 12) else {
                return
            }
            colors[0] = Float(percent)
            colors[4] = Float(percent)
            colors[8] = Float(percent)
            colors[9] = Float(percent)
            colors[10] = Float(percent)
        }
    }
}
