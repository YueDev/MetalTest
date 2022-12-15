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
            VStack(spacing:16) {
                NavigationLink(destination: WWDC22View()) {
                    Text("WWDC22(iOS16)")
                }
                NavigationLink(destination: KirbyView()) {
                    Text("Kirby")
                }
            }.padding()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
