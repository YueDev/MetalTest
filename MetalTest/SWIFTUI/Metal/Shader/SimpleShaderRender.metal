//
//  Shader.metal
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

#include <metal_stdlib>
using namespace metal;

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
    
    
    // matrix
    
    struct MatrixVertexIn {
        float4 positionAndUV [[ attribute(0) ]];
    };
    
    struct MatrixVertexOut{
        float4 position [[ position ]];
        float2 uv;
    };
    
    
    vertex MatrixVertexOut matrix_vertex
    (
     MatrixVertexIn in [[ stage_in ]],
     constant float4x4& model [[ buffer(1) ]],
     constant float4x4& view [[ buffer(2) ]],
     constant float4x4& projection [[ buffer(3) ]]
     ){
         MatrixVertexOut out;
         float4 position = float4(in.positionAndUV.xy, 0.0, 1.0);
         out.position = projection * view * model * position;
         out.uv = in.positionAndUV.zw;
         return out;
     }
    
    fragment float4 matrix_fragment
    (
     MatrixVertexOut in [[ stage_in ]],
     texture2d<float> texture [[ texture(0) ]],
     sampler sampler [[ sampler(0) ]]
     ){
         return texture.sample(sampler, in.uv);
     }
    
}
