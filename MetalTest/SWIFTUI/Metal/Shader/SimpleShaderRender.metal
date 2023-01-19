//
//  Shader.metal
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

#include <metal_stdlib>

namespace SimpleShaderRender {

    //顶点的输出 至少要包含顶点的数据float4 [[ position ]]，这样metal才知道怎么画三角形
    //这里把颜色也给加上 供片段使用。
    struct VertexOut {
        float4 position [[ position ]];
        half4 color;
    };

    // 这里顶点buffer没有采用解释数据的办法，而是直接按照数组传过来了
    // 因此需要加上const device packed_float3*, 颜色也一样。
    // 这样就需要使用unsigned int vid [[ vertex_id ]]
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

    //片段的输入是顶点的输出，即VertexOut 但是需要加上[[ stage_in ]]
    fragment half4 simple_fragment
    (
     VertexOut in [[ stage_in ]]
     ){
         return in.color;
     }
    
}
