//
//  ListView.swift
//  MetalTest
//
//  Created by YUE on 2022/12/19.
//

import SwiftUI

struct ListView1: View {
    
    private let models = {
        var data = [Model]()
        for i in (1...100) {
            data.append(Model(name: "Model \(i)"))
        }
        return data
    }()
    
    @State private var style = 0
    
    var body: some View {
        VStack { 
            switch style {
            case 0:
                List(models) { model in
                    Text(model.name)
                }
                .listStyle(.insetGrouped)
            case 1:
                List(models) { model in
                    Text(model.name)
                }
                .listStyle(.inset)
            case 2:
                List(models) { model in
                    Text(model.name)
                }
                .listStyle(.plain)
            default:
                List(models) { model in
                    Text(model.name)
                }
                .listStyle(.grouped)
            }
            
            HStack {
                Button {
                    style = 0
                } label: {
                    Text("insetGrouped")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    style = 1
                } label: {
                    Text("inset")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    style = 2
                } label: {
                    Text("plain")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    style = 3
                } label: {
                    Text("grouped")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .animation(.easeInOut, value: style)
    }
    
    
}

struct Model: Identifiable {
    let name: String
    
    var id: String {
        name
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView1()
    }
}
