//
//  ViewController.swift
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

import UIKit
import Metal
import QuartzCore
import Foundation


class ViewController: UIViewController {

    private lazy var device = {
        MTLCreateSystemDefaultDevice()
    }()

    private lazy var metalLayer = {
        CAMetalLayer()
    }()
    
    private var vertexBuffer: MTLBuffer? = nil

    private var renderPass: MTLRenderPassDescriptor? = nil

    private var pipeLineState: MTLRenderPipelineState? = nil

    private var commandQueue: MTLCommandQueue? = nil

    override func viewDidLayoutSubviews() {
        metalLayer.frame = view.layer.frame.inset(by: view.safeAreaInsets)
    }
    
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.backgroundColor = .lightGray
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true

        view.layer.addSublayer(metalLayer)
        do {
            try readyForDraw()
        } catch {
            print(error)
            return
        }
        
        startRender()
    }


    @MainActor
    private func startRender() {
        //game loop 根据屏幕的刷新来更新画面
        let timer = CADisplayLink(target: self, selector: #selector(gameLoop))
        timer.add(to: RunLoop.main, forMode: .default)
        
        //停止自动渲染
//        Task {
//            try! await Task.sleep(nanoseconds: 3_000_000_000)
//        //释放监听。临时暂停可以使用isPause = true  这都需要主线程
//            timer.remove(from: RunLoop.main, forMode: .default)
//        }
    }
    

    //渲染 draw call
    private func render() {
        print("render once")
        guard let pipeLineState = pipeLineState,
              let vertexBuffer = vertexBuffer,
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
//        //发送片元数据，没找到fragmet从vertex取数据的途径，所以这里把数据传给片元
//        renderEncoder.setFragmentBuffer(vertexBuffer, offset: 0, index: 0)
        //绘制三角形，1个
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        //endEncoding 结束渲染编码
        renderEncoder.endEncoding()

        //commandBuffer 设置drawable并提交
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    
    @objc func gameLoop() {
        autoreleasepool {
            render()
        }
    }
    

    //渲染之前的准备

    private func readyForDraw() throws {

        guard let device = self.device else {
            return
        }

        //顶点数据
        let vertexData: [Float] = [
            0.0, 0.5, 0.0,
            -0.5, -0.5, 0.0,
            0.5, -0.5, 0.0,
        ]

        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])

        //生成顶点vertexBuffer
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])

        //生成shader program
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            return
        }

        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")

        //根据pipeline的描述文件 生成pipeline state
        let pipeLineDescriptor = MTLRenderPipelineDescriptor()
        pipeLineDescriptor.vertexFunction = vertexProgram
        pipeLineDescriptor.fragmentFunction = fragmentProgram
        pipeLineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        

        pipeLineState = try device.makeRenderPipelineState(descriptor: pipeLineDescriptor)

        //生成命令队列 和 命令buffer
        commandQueue = device.makeCommandQueue()

        //render pass 可以设置color clear之类的
        renderPass = MTLRenderPassDescriptor()
        renderPass?.colorAttachments[0].loadAction = .clear
        renderPass?.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.4, 0.3, 1.0)
    }

}

