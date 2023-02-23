//
//  TestMetalView.swift
//  MetalTest
//
//  Created by YUE on 2023/2/16.
//

import SwiftUI

struct SimpleMatrixView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        MetalMatrixView(progress: progress)
        Slider(value: $progress, in: 0.0...1.0)
            .padding(32)
    }
}

struct TestMetalView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleMatrixView()
    }
}
