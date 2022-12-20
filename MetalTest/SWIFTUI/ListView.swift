//
//  ListView.swift
//  MetalTest
//
//  Created by YUE on 2022/12/19.
//

import SwiftUI

struct ListView: View {
    
    private let models = {
        var data = [Model]()
        for i in (1...100) {
            data.append(Model(name: "Model \(i)"))
        }
        return data
    }()
    
    @State private var style: any ListStyle = .insetGrouped
    
    var body: some View {
        VStack {
            List(models) { model in
                Text(model.name)
            }.listStyle(.insetGrouped)
            
            HStack {
                Button {
                    style = .insetGrouped
                } label: {
                    Text("insetGrouped")
                }.buttonStyle(.borderedProminent)
                
                Button {
                    style = .inset
                } label: {
                    Text("inset")
                }.buttonStyle(.borderedProminent)
                
                Button {
                    style = .plain
                } label: {
                    Text("plain")
                }.buttonStyle(.borderedProminent)
                
                Button {
                    style = .grouped
                } label: {
                    Text("grouped")
                }.buttonStyle(.borderedProminent)
            }
            .padding()
        }
        
    }
}

struct Model:Identifiable {
    let name:String
    
    var id:String {
        name
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView()
    }
}
