//
// Created by YUE on 2023/1/13.
//

import Foundation
import SwiftUI
import MetalKit

struct MetalMapView: UIViewRepresentable {
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
        mtkView.clearColor = MTLClearColor(red: 0.2, green: 0.3, blue: 0.2, alpha: 1.0)
        mtkView.drawableSize = mtkView.frame.size
        return mtkView
    }

    func updateUIView(_ mtkView: UIViewType, context: Context) {
        mtkView.setNeedsDisplay()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(device:device)
    }

    class Coordinator: NSObject, MTKViewDelegate {

        var device: MTLDevice?
        //渲染用的
        private var renderPass: MTLRenderPassDescriptor? = nil
        private var pipeLineState: MTLRenderPipelineState? = nil
        private var commandQueue: MTLCommandQueue? = nil


        init(device: MTLDevice?) {
            super.init()
            readyForRender()
        }

        private func readyForRender() {
            //顶点数据
            let vertexData = [
                SIMD2<Float>(-0.9, 0.9),
                SIMD2<Float>(-0.9, -0.9),
                SIMD2<Float>(0.9, 0.9),
                SIMD2<Float>(0.9, -0.9),
            ]
            let dataSize = MemoryLayout.stride(ofValue: vertexData[0]) * vertexData.count

        }


        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

        }

        func draw(in view: MTKView) {

        }

    }
}
