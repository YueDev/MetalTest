//
//  ShapeStyleView.swift
//  MetalTest
//
//  Created by YUE on 2022/12/18.
//
//  ShpeStyle会用自己去填充形状、文字等
//  Swiftui不建议自己去写ShapeStyle，而是让使用它预设好的颜色、图片、渐变等类型的ShapeStyle。

import SwiftUI

struct ShapeStyleView: View {
    var body: some View {
        VStack {
            // 用颜色的ShapeStyle去填充形状
            Circle().fill(.orange)
            // 用图片去填充形状。
            // 对形状来说，fill效率更高, fill适合形状调用，foregroundStyle适合所有View，
            Rectangle()
                .foregroundStyle(.image(Image("charaBtn-waddledee")))
            // 用渐变去填充文字
            Text("Chaocode2-4")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.linearGradient(colors: [Color.indigo, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .padding()
    }
}

struct ShapeStyleView_Previews: PreviewProvider {
    static var previews: some View {
        ShapeStyleView()
    }
}
