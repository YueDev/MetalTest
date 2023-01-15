import SwiftUI

struct SimpleMetalView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
            MetalMapView(progress: progress)
            Slider(value: $progress, in: 0.0...1.0)
                .padding(32)
        }
        
    }
}


struct SimpleMetalView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleMetalView()
    }
}

