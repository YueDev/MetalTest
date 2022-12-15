//
//  ContentView.swift
//  SwiftUITest
//
//  Created by YUE on 2022/12/5.
//

import SwiftUI

struct KirbyView: View {
    
    private let kirby = KirbyRepository.shared
    
    @State private var isShowChara = false
    
    var body: some View {
        
        ScrollView {
            VStack(spacing: 32) {
                logoView
                descriptionView
                //下边的图片clipped，但是图片好像按照原图的大小会挡住这个buttton
                //button设置z的坐标大于图片的即可，即大于默认值0即可
                charaButtonView.zIndex(1)
                gameView
            }
            .padding(EdgeInsets(top: 0, leading: 32, bottom: 0, trailing: 32))
            
        }
        .overlay {
            if isShowChara {
                charaView.edgesIgnoringSafeArea(.all)
            }
        }
        .animation(.easeInOut, value: isShowChara)
    }
    
    //MARK: - SubView
    
    var logoView: some View {
        HStack {
            Image(kirby.logo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .padding(16)
                .frame(width: 160,height: 160)
                .clipped()
                .background(Color.red.opacity(0.5))
                .clipShape(Circle())
            Spacer()
            VStack(spacing: 8) {
                Text(kirby.kirbyName.name)
                    .font(.title2).bold().padding(16)
                Text(kirby.kirbyName.jp)
                    .font(.subheadline).foregroundColor(.secondary)
                Text(kirby.kirbyName.en)
                    .font(.subheadline).foregroundColor(.secondary)
            }
        }
    }
    
    var descriptionView: some View {
        Text(kirby.description).font(.subheadline)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    var charaButtonView: some View {
        Button {
            isShowChara = true
        } label: {
            Text("Charactor")
                .font(.title2).bold()
                .frame(maxWidth:.infinity)
                .foregroundColor(Color.white)
                .padding(16)
                .background(RoundedRectangle.init(cornerRadius: 16).foregroundColor(.red.opacity(0.75)))
        }
        
        
    }
    
    var gameView: some View {
        VStack(spacing: 0) {
            Text("Game")
                .font(.title2).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
            ForEach.init(kirby.games.indices, id: \.self) { index in
                HStack {
                    let game = kirby.games[index]
                    VlineShape(lineStyle: index == 0 ? .top :
                                index == kirby.games.count - 1 ? .bottom : .middle)
                    .frame(width: 64)
                    .foregroundColor(Color.gray)

                    VStack(spacing:8) {
                        Image(game.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 128)
                            .clipped()
                        Group {
                            Text(game.name).bold()
                            Text(game.time)
                                .font(.caption)
                            Text(game.description).font(.caption)
                                .padding(.bottom)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                    }
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle.init(cornerRadius: 16))
                    .padding(.bottom, 8)
                }
            }
            
        }
    }
    
    var charaView: some View {
        ZStack(){
            Color.black.frame(maxWidth: .infinity, maxHeight: .infinity).opacity(0.5)
                .onTapGesture {
                    isShowChara = false
                }
            KirbyCharaView(isShowChara: $isShowChara)
        }
    }
    
}




//MARK: - Preview

struct KirbyViewView_Previews: PreviewProvider {
    static var previews: some View {
        KirbyView()
    }
}
