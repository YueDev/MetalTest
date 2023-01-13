//
//  ContentView.swift
//  MetalTest
//
//  Created by YUE on 2022/12/12.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                NavigationLink(destination: WWDC22View()) {
                    homeText("WWDC22(iOS16)")
                }
                NavigationLink(destination: KirbyView()) {
                    homeText("Kirby")
                }
                NavigationLink(destination: ShapeStyleView()) {
                    homeText("ShapeStyle")
                }
                NavigationLink(destination: ListView1()) {
                    homeText("ListView1")
                }
                NavigationLink(destination: ListView2()) {
                    homeText("ListView2")
                }
                NavigationLink(destination: MetalTextView()) {
                    homeText("MetalTextView")
                }
            }
                .padding()
        }
    }

    func homeText(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.white)
            .font(.callout)
            .padding(12)
            .roundedRectBackground(radius: CGFloat.infinity, style: .orange)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}


extension View {
    func roundedRectBackground(radius: CGFloat = 8.0, style: some ShapeStyle) -> some View {
        background(RoundedRectangle(cornerRadius: radius).fill(style))
    }
}
