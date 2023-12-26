//
//  MetalVideo2View.swift
//  MetalTest
//
// fotoplay用的 两个纹理与视频已经对计算函数进行转场
// mix
//


import Foundation
import SwiftUI
import MetalKit
import MetalPerformanceShaders
import AVFoundation

struct MetalVideoMixView: UIViewRepresentable {
    
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
        private let kernelShaderName = "TransitionVideo::transition_video_mix"
        private let videoFileName = "tran_video_mix_1.mp4"
//        private let videoFileName = "tran_video_mix_2.mp4"

        
        // 纹理
        private var samplerState: MTLSamplerState? = nil
        private var texture1: MTLTexture? = nil
        private var texture2: MTLTexture? = nil
        private var renderTexure: MTLTexture? = nil

        // 转场进度
        private var progress: Float = 0.0
        // 比例
        private var ratio: Float = 1.0
        
        // 计算函数
        private var computePipelineState: MTLComputePipelineState!
        private var commandQueue: MTLCommandQueue? = nil

        private var defaultLibrary: MTLLibrary? = nil
        
        //渲染用
        private let vertexShaderName = "TextureRender::shader_vertex"
        private let fragmentShaderName = "TextureRender::shader_fragment"
        private var vertexBuffer: MTLBuffer? = nil
        private var renderPass: MTLRenderPassDescriptor? = nil
        private var renderPipelineState: MTLRenderPipelineState? = nil
        
        //视频用
        private var asset: AVAsset? = nil
        private var imageGenerator:AVAssetImageGenerator? = nil
        
        init(device: MTLDevice?) {
            super.init()
            self.device = device
            
            guard let url = Bundle.main.url(forResource: videoFileName, withExtension: nil) else {return}
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.requestedTimeToleranceBefore = .zero
            imageGenerator.requestedTimeToleranceAfter = .zero
            
            self.imageGenerator = imageGenerator
            self.asset = asset
            readyForCompute()
            readyForRender()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            guard size.width > 0 && size.height > 0 else {
                return
            }
            
            ratio = Float(size.width / size.height)
            
            view.setNeedsDisplay()
        }
        
        
        func draw(in view: MTKView) {
            compute()
            render(in: view)
        }
        
        //更新进度
        func changeProgress(_ progress: Float) {
            self.progress = progress
        }
        
        
        // 准备计算
        private func readyForCompute() {
            guard let device = device else {
                return
            }
            
            defaultLibrary = device.makeDefaultLibrary()
            
            
            //生成fucction
            guard let defaultLibrary = defaultLibrary,
                  let funcftion = defaultLibrary.makeFunction(name: kernelShaderName) else {
                return
            }
            
            // 生成pipelineState
            computePipelineState = try? device.makeComputePipelineState(function: funcftion)
            
            commandQueue = device.makeCommandQueue()
            
            // 计算的输入纹理
            let textureName1 = TextureManager.getPeopleTextureName()
            texture1 = TextureManager.defaultTextureByAssets(device: device, name: textureName1)
            let textureName2 = TextureManager.getPeopleTextureName()
            texture2 = TextureManager.defaultTextureByAssets(device: device, name: textureName2)
            
            // 计算的输出纹理，即渲染的纹理
            if let texture1 = texture1 {
                renderTexure = TextureManager.newTextureForKernel(device: device, width: texture1.width, height: texture1.height)
            }
            
            samplerState = TextureManager.defaultSamplerState(device: device)
        }
        
        
        // 准备渲染
        private func readyForRender() {
            guard let device = device else {
                return
            }
            
            guard let defaultLibrary = defaultLibrary else {
                return
            }
            
            //顶点数据 position和纹理的uv
            //这里之前是用的4个SIMD4，直接改成16个长度的Float数组也行。
            let vertexData: [Float] = [
                -1.0, 1.0, 0.0, 0.0,
                -1.0, -1.0, 0.0, 1.0,
                1.0, 1.0, 1.0, 0.0,
                1.0, -1.0, 1.0, 1.0,
            ]
            
            let vertexDataSize = MemoryLayout.stride(ofValue: vertexData[0]) * vertexData.count
            vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexDataSize, options: [])

            
            //生成shader program
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

            renderPipelineState = try? device.makeRenderPipelineState(descriptor: pipeLineDescriptor)
            

            //生成命令队列 和 命令buffer
            commandQueue = device.makeCommandQueue()
        }
        
        //获取视频帧
        private func getVideoFrame(at time: CMTime) -> CGImage?{
            guard let imageGenerator = imageGenerator else {return nil}
            return try? imageGenerator.copyCGImage(at: time, actualTime: nil)
        }
        
        
        // 计算流程，将两个输入纹理经过计算输出到renderTexure
        private func compute() {
            
            //获取视频帧数
            guard let asset = asset else {return}
            let second = Double(progress) * asset.duration.seconds
            let time = CMTimeMakeWithSeconds(second, preferredTimescale: asset.duration.timescale)
            guard let frame = getVideoFrame(at: time) else {return}
            guard let videoTexture = TextureManager.toMTLTexture(cgImage: frame, device: device) else {return}
            
            
            guard
                let texture1 = texture1,
                let texture2 = texture2,
                let renderTexure = renderTexure,
                let pipelineState = computePipelineState,
                let commandBuffer = commandQueue?.makeCommandBuffer(),
                let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            else {
                return
            }
            
            commandEncoder.setComputePipelineState(pipelineState)
            
            // 设置transition参数
            commandEncoder.setBytes(&progress, length: MemoryLayout.stride(ofValue: progress), index: 0)
            commandEncoder.setBytes(&ratio, length: MemoryLayout.stride(ofValue: ratio), index: 1)


            // 设置纹理
            commandEncoder.setTexture(texture1, index: 0)
            commandEncoder.setTexture(texture2, index: 1)
            commandEncoder.setTexture(renderTexure, index: 2)
            commandEncoder.setTexture(videoTexture, index: 3)
            commandEncoder.setSamplerState(samplerState, index: 0)
            
            // 设置平行计算的threead和group
            let width: Int = pipelineState.threadExecutionWidth
            let height: Int = pipelineState.maxTotalThreadsPerThreadgroup / width
            let threadsPerThreadgroup: MTLSize = MTLSizeMake(width, height, 1)
            let threadgroupsPerGrid: MTLSize = MTLSize(width: (renderTexure.width + width - 1) / width,
                                                       height: (renderTexure.height + height - 1) / height,
                                                       depth: 1)
            commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            
            commandEncoder.endEncoding()
            commandBuffer.commit()
        }
        
        private func render(in view: MTKView) {
            //drawable和renderPassDescriptor要用MTKView的
            guard
                   let texture = renderTexure,
                   let samplerSate = samplerState,
                   let drawable = view.currentDrawable,
                   let renderPass = view.currentRenderPassDescriptor,
                   let renderPipelineState = renderPipelineState,
                   let commandBuffer = commandQueue?.makeCommandBuffer()
            else {
                return
            }

            renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.4, 0.3, 1.0)
            renderPass.colorAttachments[0].loadAction = .clear

            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
                return
            }

            renderEncoder.setRenderPipelineState(renderPipelineState)
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

