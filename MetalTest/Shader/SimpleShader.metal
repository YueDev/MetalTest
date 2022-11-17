//
//  Shader.metal
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

#include <metal_stdlib>
using namespace metal;

//输入结构 由于stage_in要求有attribute(0)，因此需要包装下
struct VertexIn {
    float4 positionAndUV [[ attribute(0) ]];
};

struct VertexOut{
    float4 position [[ position ]];
    float2 uv;
};


vertex VertexOut simple_vertex
(
 VertexIn in [[ stage_in ]],
 constant float2& vertexScale [[ buffer(1) ]]
 ) {
    VertexOut out;
    out.position = float4(in.positionAndUV.xy * vertexScale, 0.0, 1.0);
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



fragment float4 simple_fragment_slide_left
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    float2 uv = in.uv;

    float2 f = fract(uv + float2(progress, 0.0));

    float4 out1 = texture1.sample(sampler, f);
    float4 out2 = texture2.sample(sampler, f);

    return mix(out1, out2, step(1.0 - uv.x, progress));
}


fragment float4 simple_fragment_slide_right
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    float2 uv = in.uv;

    float2 f = fract(uv - float2(progress, 0.0));

    float4 out1 = texture1.sample(sampler, f);
    float4 out2 = texture2.sample(sampler, f);

    return mix(out1, out2, step(uv.x, progress));
}


fragment float4 simple_fragment_slide_up
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    float2 uv = in.uv;

    float2 f = fract(uv + float2(0.0, progress));

    float4 out1 = texture1.sample(sampler, f);
    float4 out2 = texture2.sample(sampler, f);

    return mix(out1, out2, step(1.0 - uv.y, progress));
}


fragment float4 simple_fragment_slide_down
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    float2 uv = in.uv;

    float2 f = fract(uv - float2(0.0, progress));

    float4 out1 = texture1.sample(sampler, f);
    float4 out2 = texture2.sample(sampler, f);

    return mix(out1, out2, step(uv.y, progress));
}


fragment float4 simple_fragment_cover_left
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    float2 uv = in.uv;

    float4 out1 = texture1.sample(sampler, uv);
    float4 out2 = texture2.sample(sampler, uv);

    return mix(out1, out2, step(uv.x, progress));
}

fragment float4 simple_fragment_cover_right
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    float2 uv = in.uv;

    float4 out1 = texture1.sample(sampler, uv);
    float4 out2 = texture2.sample(sampler, uv);

    return mix(out1, out2, step(1.0 - uv.x, progress));
}

fragment float4 simple_fragment_cover_up
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    float2 uv = in.uv;

    float4 out1 = texture1.sample(sampler, uv);
    float4 out2 = texture2.sample(sampler, uv);

    return mix(out1, out2, step(1.0 - uv.y, progress));
}

fragment float4 simple_fragment_cover_down
(
 VertexOut in [[ stage_in ]],
 texture2d<float> texture1 [[ texture(0) ]],
 texture2d<float> texture2 [[ texture(1) ]],
 sampler sampler [[ sampler(0) ]],
 constant float& progress [[ buffer(0) ]]
 ){
    float2 uv = in.uv;

    float4 out1 = texture1.sample(sampler, uv);
    float4 out2 = texture2.sample(sampler, uv);

    return mix(out1, out2, step(uv.y, progress));
}