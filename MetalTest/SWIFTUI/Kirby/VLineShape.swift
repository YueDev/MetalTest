//
//  VLineShape.swift
//  SwiftUITest
//
//  Created by YUE on 2022/12/10.
//

import Foundation
import SwiftUI

struct VlineShape: Shape {
    
    enum LineStyle {case top, middle, bottom}
    
    var dotSize: CGFloat = 16
    var lineWidth: CGFloat = 4
    var lineStyle = LineStyle.middle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let lineX = rect.midX - lineWidth / 2
        var lineY = CGFloat.init(0)
        let rectWidth = lineWidth
        var rectHeight = rect.height
        
        let dotX = rect.midX - dotSize / 2
        var dotY = rect.midY - dotSize / 2
        
        let offsetY = rect.height * 0.2
        
        if lineStyle == .top {
            lineY += offsetY
            dotY = offsetY - dotSize / 2
        } else if lineStyle == .bottom {
            rectHeight -= offsetY
            dotY = rect.height - offsetY - dotSize / 2
        }
        
        path.addRect(CGRect.init(x: lineX, y: lineY, width: rectWidth, height: rectHeight))
        path.addEllipse(in: CGRect(x: dotX, y: dotY, width:dotSize, height: dotSize))
        
        return path
    }
    
}

//MARK: - Preview

struct VlineShape_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing:0) {
            VlineShape(lineStyle: .top).background(Color.blue.opacity(0.5))
            VlineShape(lineStyle: .middle).background(Color.red.opacity(0.5))
            VlineShape(lineStyle: .bottom).background(Color.yellow.opacity(0.5))
        }
    }
}

