//
//  Shader.metal
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[ attribute(0) ]];
    float4 color1 [[ attribute(1) ]];
    float4 color2 [[ attribute(2) ]];
};

struct VertexOut{
    float4 position [[ position ]];
    float4 color1;
    float4 color2;
};


vertex VertexOut basic_vertex
(
 VertexIn in [[ stage_in ]]
 ) {
    VertexOut out;
    out.position = float4(in.position, 1.0);
    out.color1 = in.color1;
    out.color2 = in.color2;
    return out;
}


fragment half4 basic_fragment
(
 VertexOut in [[ stage_in ]]
 ){
    return half4(in.color2);
}
