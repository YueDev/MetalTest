//
//  ListView2.swift
//  MetalTest
//
//  Created by YUE on 2023/1/4.
//

import SwiftUI

struct ListView2: View {
    
    @State private var models =  {
        var data = [Model]()
        for i in (1...100) {
            data.append(Model(name: "Model \(i)"))
        }
        return data
    }()
    
    //预览有BUG 用真机/模拟器
    var body: some View {
        if #available(iOS 16.0, *) {
            List($models, editActions:.all) { $model in
                Text(model.name)
            }
        } else {
            //ios16以下用这个，比较灵活
            List {
                Section {
                    Text("拖动排序 滑动删除")
                }
                ForEach(models) { model in
                    Text(model.name)
                }.onMove { indexSet, offset in
                    models.move(fromOffsets: indexSet, toOffset: offset)
                }.onDelete { indexSet in
                    models.remove(atOffsets: indexSet)
                }
            }.listStyle(.insetGrouped)
        }
        
    }
}

struct ListView2_Previews: PreviewProvider {
    static var previews: some View {
        ListView2()
    }
}
