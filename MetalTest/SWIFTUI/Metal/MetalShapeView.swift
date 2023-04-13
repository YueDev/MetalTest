//
//  MetalShapeView.swift
//  MetalTest
//
//  Created by YUE on 2023/3/23.
//

import SwiftUI
import MetalKit

struct MetalShapeView: UIViewRepresentable {
    
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
        context.coordinator.changeProgress(progress: Float(progress))
        mtkView.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(device: device)
    }
    
    
    
    class Coordinator: NSObject, MTKViewDelegate {
        
        var device: MTLDevice?

        private let vertexShaderName = "SimpleShaderRender::shape_vertex"
        private let fragmentShaderName = "SimpleShaderRender::shape_fragment"
        
        //buffer
        private var vertexBuffer: MTLBuffer? = nil
        private var progressBuffer: MTLBuffer? = nil
        private var ratioBufer: MTLBuffer? = nil
        
        //纹理
        private var samplerState: MTLSamplerState? = nil
        private var texture: MTLTexture? = nil
        
        //渲染
        private var renderPass: MTLRenderPassDescriptor? = nil
        private var pipeLineState: MTLRenderPipelineState? = nil
        private var commandQueue: MTLCommandQueue? = nil
    
        
        
        public func changeProgress(progress: Float) {
            guard let ptr = progressBuffer?.contents().bindMemory(to: Float.self, capacity: 1) else {
                return
            }
            ptr.pointee = progress
        }
        
        
        init(device: MTLDevice?) {
            super.init()
            self.device = device
            readyForRender()
        }
        //尺寸更改
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            guard
                let ptr = ratioBufer?.contents().bindMemory(to: Float.self, capacity: 1),
                size.width > 0,
                size.height > 0
            else {
                return
            }
            let scale = Float(size.width) / Float(size.height)
            ptr.pointee = scale
            view.setNeedsDisplay()
        }
        
        func draw(in view: MTKView) {
            render(in: view)
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
            
            //fragment buffer
            var progress : Float = 0.5
            progressBuffer = device.makeBuffer(bytes: &progress, length: MemoryLayout<Float>.stride, options: [])
            var ratio = 1.0
            ratioBufer = device.makeBuffer(bytes: &ratio, length: MemoryLayout<Float>.stride, options: [])

            
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
            texture = TextureManager.defaultTextureByAssets(device: device, name: "landscape")
            samplerState = TextureManager.defaultSamplerState(device: device)
            
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
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
                return
            }
            renderEncoder.setRenderPipelineState(pipeLineState)
            
            //发送顶点buffer
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            //fragment buffer
            renderEncoder.setFragmentBuffer(progressBuffer, offset: 0, index: 1)
            renderEncoder.setFragmentBuffer(ratioBufer, offset: 0, index: 2)

            
            //设置纹理
            renderEncoder.setFragmentTexture(texture, index: 0)
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





//preview
struct MetalShapeView_Previews: PreviewProvider {
    static var previews: some View {
        MetalShapeView(progress: 0.5)
    }
}
