//
//  KirbyCharaView.swift
//  SwiftUITest
//
//  Created by YUE on 2022/12/6.
//

import SwiftUI

struct KirbyCharaView: View {
    
    private let charas = KirbyRepository.shared.charas
    
    @Binding var isShowChara: Bool
    
    var body: some View {
        VStack() {
            HStack {
                ForEach(charas, id: \.name) { chara in
                    VStack {
                        Image(chara.icon)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        Text(chara.name).font(.caption)
                    }.onTapGesture {
                        //点击跳转网页
                        guard let url = URL(string: chara.url) else {
                            return
                        }
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            Button {
                isShowChara = false
            } label: {
                Text("Close").font(.title3).padding(8)
            }
        }
        .padding(.all, 16)
        .background(RoundedRectangle.init(cornerRadius: 16).foregroundColor(Color.red.opacity(0.5)))
        .background(RoundedRectangle.init(cornerRadius: 16).foregroundColor(Color.white))

    }
}




//MARK: - Preview

struct KirbyCharaView_Previews: PreviewProvider {
    static var previews: some View {
        KirbyCharaView(isShowChara: .constant(true))
    }
} 
