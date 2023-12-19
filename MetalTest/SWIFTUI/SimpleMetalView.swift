import SwiftUI



struct SimpleMetalKernelTransitionView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
            MetalKernelTransitionView(progress: progress)
            HStack {
                Slider(value: $progress, in: 0.0...1.0)
                    .padding(32)
            }
        }

    }
}


struct SimpleMetalVideoView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
        MetalVideoView(progress: progress)
        Slider(value: $progress, in: 0.0...1.0)
            .padding(32)
        }

    }
}


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

struct SimpleTextureView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
            MetalTextureView(progress: progress)
            Slider(value: $progress, in: 0.0...1.0)
                .padding(32)
        }
        
    }
}

struct SimpleMatrixView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
        MetalMatrixView(progress: progress)
        Slider(value: $progress, in: 0.0...1.0)
            .padding(32)
        }

    }
}

struct SimpleMetalShapeView: View {
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
            MetalShapeView(progress: progress)
            Slider(value: $progress, in: 0.0...1.0)
                .padding(32)
        }
    }
}

struct SimpleZoomBlurView: View {
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
            MetalZoomBlurView(progress: progress)
            Slider(value: $progress, in: 0.0...1.0)
                .padding(32)
        }
    }
}

struct SimpleGaussianBlurView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
            MetalGaussianBlurView(progress: progress)
            Slider(value: $progress, in: 0.0...1.0)
                .padding(32)
        }
    }
}

struct SimpleRotateView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
            MetalRotateView(progress: progress)
            Slider(value: $progress, in: 0.0...1.0)
                .padding(32)
        }
    }
}

struct SimpleRotateBlurView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
            MetalRotateBlurView(progress: progress)
            Slider(value: $progress, in: 0.0...1.0)
                .padding(32)
        }
    }
}

struct SimpleCardView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
            MetalCardView(progress: progress)
            Slider(value: $progress, in: 0.0...1.0)
                .padding(32)
        }
    }
}

struct SimpleMSAAView: View {
    
    @State private var progress = 0.5
    
    var body: some View {
        VStack {
        MetalMSAAView(progress: progress)
                .aspectRatio(1.0, contentMode: .fit)
        Slider(value: $progress, in: 0.0...1.0)
            .padding(32)
        }

    }
}
