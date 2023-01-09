//
// Created by YUE on 2023/1/9.
//

import Foundation

struct TCBitmap {
    let uuid: String
    let width: Int
    let height: Int
}


class TCRectF {
    var left: Float
    var top: Float
    var right: Float
    var bottom: Float

    init(left: Float, top: Float, right: Float, bottom: Float) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }
}


class TCResult {
    private var out = [String: TCRectF]()

    func add(uuid: String, tcRectF: TCRectF) {
        out[uuid] = tcRectF
    }

    func get(uuid: String) -> TCRectF? {
        out[uuid]
    }

}


class TCRect {
    var left: Double
    var top: Double
    var right: Double
    var bottom: Double

    init(left: Double, top: Double, right: Double, bottom: Double) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }


    func getRectF() -> TCRectF {
        TCRectF(
               left: Float(left),
               top: Float(top),
               right: Float(left + right),
               bottom: Float(top + bottom)
        )
    }
}


class TCCollageItem {
    var uuid: String?
    var ratioRect: TCRect

    init(uuid: String?, ratioRect: TCRect) {
        self.uuid = uuid
        self.ratioRect = ratioRect
    }

    func getRatioMaxBound(canvasWidth: Double, canvasHeight: Double) -> Double {
        max(canvasWidth * ratioRect.right, canvasHeight * ratioRect.bottom)
    }
}
