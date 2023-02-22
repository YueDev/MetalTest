//
//  OffscreenShader.metal
//  MetalTest
//
//  Created by YUE on 2023/2/17.
//

#include <metal_stdlib>
#include "Model.metal"
using namespace metal;
using namespace Model;

namespace OffscreenShader {
    
    //主要shader 渲染到屏幕上
    vertex VertexOut main_vertex(VertexIn in [[ stage_in ]]) {
         VertexOut out;
         out.position = float4(in.positionAndUV.xy, 0.0, 1.0);
         out.uv = in.positionAndUV.zw;
         return out;
     }
    fragment float4 main_fragment
    (
     VertexOut in [[ stage_in ]],
     texture2d<float> texture [[ texture(0) ]],
     sampler sampler [[ sampler(0) ]]
     ){
         return texture.sample(sampler, in.uv);
     }
    
    
    //离屏shader
    // model是矩阵
    vertex VertexOut offscreen_vertex
    (
     VertexIn in [[ stage_in ]],
     constant float4x4& model [[ buffer(1) ]],
     constant float4x4& view [[ buffer(2) ]],
     constant float4x4& projection [[ buffer(3) ]]
    ){
         VertexOut out;
         out.position = projection * view * model * float4(in.positionAndUV.xy, 0.0, 1.0);
         out.uv = in.positionAndUV.zw;
         return out;
     }
    fragment float4 offscreen_fragment
    (
     VertexOut in [[ stage_in ]],
     texture2d<float> texture [[ texture(0) ]],
     sampler sampler [[ sampler(0) ]]
     ){
         float4 out = texture.sample(sampler, in.uv);
//         out.a *= 0.75;
//         out = float4(0.0, 1.0, 0.0, 1.0);
         return out;
     }
}


