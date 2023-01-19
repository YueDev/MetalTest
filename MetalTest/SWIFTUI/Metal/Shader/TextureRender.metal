//
//  Shader.metal
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

#include <metal_stdlib>

using namespace metal;

namespace TextureRender {

    //输入结构 由于stage_in要求有attribute(0)，因此需要包装下
    struct VertexIn {
        float4 positionAndUV [[ attribute(0) ]];
    };

    struct VertexOut{
        float4 position [[ position ]];
        float2 uv;
    };

    vertex VertexOut shader_vertex
    (
    VertexIn in [[ stage_in ]]
     ){
         VertexOut out;
         out.position = float4(in.positionAndUV.xy, 0.0, 1.0);
         out.uv = in.positionAndUV.zw;
         return out;
     }


    fragment half4 shader_fragment
    (
     VertexOut in [[ stage_in ]],
     texture2d<half> texture [[ texture(0) ]],
     sampler sampler [[ sampler(0) ]]
     ){
         return texture.sample(sampler, in.uv);
     }
    
}
