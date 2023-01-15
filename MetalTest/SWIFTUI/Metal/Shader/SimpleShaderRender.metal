//
//  Shader.metal
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

#include <metal_stdlib>

namespace SimpleShaderRender {
    
    struct VertexOut {
        float4 position [[ position ]];
        half4 color;
    };
    
    vertex VertexOut simple_vertex
    (
     const device packed_float3* vertex_array [[ buffer(0) ]],
     const device packed_float3* color_array [[ buffer(1) ]],
     unsigned int vid [[ vertex_id ]]
     ){
         VertexOut out;
         out.position = float4(vertex_array[vid], 1.0);
         out.color = half4(float4(color_array[vid], 1.0));
         return out;
     }
    
    fragment half4 simple_fragment
    (
     VertexOut in [[ stage_in ]]
     ){
         return in.color;
     }
    
}
