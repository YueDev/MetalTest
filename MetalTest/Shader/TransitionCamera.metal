//
//  TransitionCamera.metal
//  MetalTest
//
//  Created by YUE on 2022/11/23.
//

#include <metal_stdlib>
#include "Model.metal"
using namespace metal;
using namespace Model;

namespace TransitionCamera01 {
    kernel void camera_01
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ) {
         
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
     }
}


