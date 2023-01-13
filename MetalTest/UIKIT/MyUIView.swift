//
// Created by YUE on 2023/1/13.
//

import Foundation
import UIKit
import MetalKit

class MetalView: MTKView {

    init(frame frameRect: CGRect) {
        super.init(frame: frameRect, device: MTLCreateSystemDefaultDevice())
        delegate = self
        backgroundColor = .red
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}

extension MetalView: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }

    public func draw(in view: MTKView) {

    }
}