//
//  Shader.metal
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 positionAndUV [[ attribute(0) ]];
    float4 color1 [[ attribute(1) ]];
    float4 color2 [[ attribute(2) ]];
};

struct VertexOut{
    float4 position [[ position ]];
    float2 uv;
    float4 color1;
    float4 color2;
};


vertex VertexOut simple_vertex
(
 VertexIn in [[ stage_in ]],
 constant float2& vertexScale [[ buffer(1) ]]
 ) {
    VertexOut out;
    out.position = float4(in.positionAndUV.xy * vertexScale, 0.0, 1.0);
    out.color1 = in.color1;
    out.color2 = in.color2;
    out.uv = in.positionAndUV.zw;
    return out;
}


fragment float4 simple_fragment_mix
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    
    return mix(texture1.sample(sampler, in.uv), texture2.sample(sampler, in.uv), progress);
}



fragment float4 simple_fragment_slide
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    float2 p = in.uv + progress;
    float2 f = fract(p);
    return texture1.sample(sampler, f);
}
