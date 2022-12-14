//
//  WWDC22View.swift
//  SwiftUITest
//
//  Created by YUE on 2022/12/11.
//

import SwiftUI

struct WWDC22View: View {
    
    let range = 0.0...1.0
    
    @State private var progress = 0.5
    @State private var isShowSheet = false
    
    var body: some View {
        
        //以下view需要ios16 基本上没啥用了 低版本还要自己写
        
        if #available(iOS 16.0, *) {
            VStack(spacing: 16) {
                HStack {
                    //sf symbols随着进度改变，可以用做简单的动画
                    Image(systemName: "wifi", variableValue: progress).font(.largeTitle)
                    Image(systemName: "square.3.layers.3d", variableValue: progress).font(.largeTitle)
                    Image(systemName: "cellularbars", variableValue: progress).font(.largeTitle)
                    Image(systemName: "touchid", variableValue: progress).font(.largeTitle)
                    
                }
                //量表，ios风格的progress bar
                Gauge(value: progress) {
                    Text("Title")
                } currentValueLabel: {
                    Text(progress.formatted(.number.precision(.fractionLength(2))))
                } minimumValueLabel: {
                    Text(range.lowerBound.description)
                } maximumValueLabel: {
                    Text(range.upperBound.description)
                }
                Slider(value: $progress, in: range)
                 
                Button("sheet") {
                    isShowSheet = true
                }.sheet(isPresented: $isShowSheet) {
                    //sheet弹出的高度，0.2 0.5 0.7 类似android的bottomsheetdialog的peekHeight
                    Text("This is a sheet.")
                        .presentationDetents([.fraction(0.2), .fraction(0.5), .fraction(0.7)])
                }
                .buttonStyle(.borderedProminent)
                
            }
            .padding(16)
            .frame(maxHeight: .infinity)
            //渐变色 很漂亮
            .background(Color.orange.opacity(0.7).gradient)
        }
    }
}

struct WWDC22View_Previews: PreviewProvider {
    static var previews: some View {
        WWDC22View()
    }
}
