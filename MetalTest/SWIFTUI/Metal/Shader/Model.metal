//
//  Model.metal
//  MetalTest
//
//  Created by YUE on 2022/11/21.
//

#include <metal_stdlib>
using namespace metal;


namespace Model {
    
    constant const float PI = 3.1415926;

    //输入结构 由于stage_in要求有attribute(0)，因此需要包装下
    struct VertexIn {
        float4 positionAndUV [[ attribute(0) ]];
    };

    struct VertexOut{
        float4 position [[ position ]];
        float2 uv;
    };
}

