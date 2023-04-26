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
    
    
    //MARK: - blur
    
    // https://github.com/BradLarson/GPUImage3/blob/master/framework/Source/Operations/ZoomBlur.metal
    // zoom blur
    // size: 模糊强度。center模糊中心点
    // 用的半径度提高效率
    fragment half4 zoom_fragment
    (
     MatrixVertexOut in [[ stage_in ]],
     texture2d<half> texture [[ texture(0) ]],
     sampler sampler [[ sampler(0) ]],
     constant float& size [[ buffer(0) ]]
     ){
         float2 uv = float2(in.uv);
         
         float2 center = float2(0.5, 0.5);

         float2 samplingOffset = 1.0/100.0 * (center - uv) * size;
         
//         float2 samplingOffset = float2(0, 1.0/100.0 * size);
         
         half4 color = texture.sample(sampler, uv)  * 0.18h;
         
         color += texture.sample(sampler, uv + samplingOffset) * 0.15h;
         color += texture.sample(sampler, uv + (2.0h * samplingOffset)) *  0.12h;
         color += texture.sample(sampler, uv + (3.0h * samplingOffset)) * 0.09h;
         color += texture.sample(sampler, uv + (4.0h * samplingOffset)) * 0.05h;
         color += texture.sample(sampler, uv - samplingOffset) * 0.15h;
         color += texture.sample(sampler, uv - (2.0h * samplingOffset)) *  0.12h;
         color += texture.sample(sampler, uv - (3.0h * samplingOffset)) * 0.09h;
         color += texture.sample(sampler, uv - (4.0h * samplingOffset)) * 0.05h;
         
         return color;
     }

    
    // 旋转坐标
    // uv输入坐标 rotate旋转弧度 rotateCenter旋转中心 ratio图片的比例
    // 返回旋转后的坐标
    float2 rotateUV(float2 uv, float rotate, float2 rotateCenter, float ratio) {
        
        float aSin = sin(rotate);
        float aCos = cos(rotate);

        float2x2 rotMat = float2x2(aCos, -aSin, aSin, aCos);
        float2x2 scaleMat = float2x2(ratio, 0.0, 0.0, 1.0);
        float2x2 scaleMatInv = float2x2(1.0 / ratio, 0.0, 0.0, 1.0);

        float2 pos = uv;
        
        pos -= rotateCenter;
        pos = scaleMatInv * rotMat * scaleMat * pos;
        pos += rotateCenter;
        return pos;
    }
    
    
    //着色器旋转图片
    fragment half4 rotate_fragment
    (
     MatrixVertexOut in [[ stage_in ]],
     texture2d<half> texture [[ texture(0) ]],
     sampler sampler [[ sampler(0) ]],
     constant float& size [[ buffer(0) ]],
     constant float& ratio[[ buffer(1) ]]
     ){
         float2 uv = in.uv;
         
         float rotate = size * 2 * 3.14159;
         
         float2 center = float2(0.5, 0.5);
         
         uv = rotateUV(uv, rotate, center, ratio);
         
         half4 color = texture.sample(sampler, uv);
         
         return color;
     }
    
    //旋转模糊
    fragment half4 rotate_blur_fragment
    (
     MatrixVertexOut in [[ stage_in ]],
     texture2d<half> texture [[ texture(0) ]],
     sampler sampler [[ sampler(0) ]],
     constant float& size [[ buffer(0) ]],
     constant float& ratio[[ buffer(1) ]]
     ){
         float2 uv = in.uv;
         
         float2 center = float2(0.5, 0.5);
         
         float angle = 0.01 * size;
         
         float2 uvOffset1 = rotateUV(uv, angle, center, ratio);
         float2 uvOffset2 = rotateUV(uv, 2.0 * angle, center, ratio);
         float2 uvOffset3 = rotateUV(uv, 3.0 * angle, center, ratio);
         float2 uvOffset4 = rotateUV(uv, 4.0 * angle, center, ratio);
         
         float2 uvOffset1n = rotateUV(uv, -angle, center, ratio);
         float2 uvOffset2n = rotateUV(uv, -2.0 * angle, center, ratio);
         float2 uvOffset3n = rotateUV(uv, -3.0 * angle, center, ratio);
         float2 uvOffset4n = rotateUV(uv, -4.0 * angle, center, ratio);
         
         half4 color = texture.sample(sampler, uv)  * 0.18h;
         
         color += texture.sample(sampler, uvOffset1) * 0.15h;
         color += texture.sample(sampler, uvOffset2) *  0.12h;
         color += texture.sample(sampler, uvOffset3) * 0.09h;
         color += texture.sample(sampler, uvOffset4) * 0.05h;
         
         color += texture.sample(sampler, uvOffset1n) * 0.15h;
         color += texture.sample(sampler, uvOffset2n) *  0.12h;
         color += texture.sample(sampler, uvOffset3n) * 0.09h;
         color += texture.sample(sampler, uvOffset4n) * 0.05h;
         
         return color;
     }
    
    //MARK: - shape
    
    vertex MatrixVertexOut shape_vertex
    (
     MatrixVertexIn in [[ stage_in ]]
     ){
         MatrixVertexOut out;
         out.position = float4(in.positionAndUV.xy, 0.0, 1.0);
         out.uv = in.positionAndUV.zw;
         return out;
     }
    
    float2 rotate(float2 uv, float arc) {
      return float2x2(cos(arc), sin(arc), -sin(arc), cos(arc)) * uv;
    }
    
    //圆形 center圆心 r是半径  返回大于0 不再圆内， 小于 0 圆内部 等于0 圆环
    float sdfCircle(float2 uv, float2 center, float r) {
        return length(uv - center) - r;
    }
    
    //方形 center方形的中心 size方形的尺寸 边长/2
    float sdfSquare(float2 uv, float2 center, float size) {
        float2 pos = uv - center;
        return max(abs(pos.x), abs(pos.y)) - size;
    }
    
    //圆角矩形
    float sdRoundedBox(float2 uv, float2 size, float2 center, float radius)
    {
        float2 pos = uv - center;
        float2 d = abs(pos) - size + radius;
        return length(max(d, 0.0)) + min(max(d.x,d.y), 0.0) - radius;
    }
    
    //画一个圆和一个方
    float3 drawScreen1(float2 uv) {
        
        //先画圆形
        float2 center = float2(0.5, 0.5);
        float r = 0.25;
        float d = sdfCircle(uv, center, r);
        float3 bg = float3(0.2, 0.2, 0.3);
        float3 colorCircle = float3(0.5, 0.6, 0.8);
        float3 color = mix(colorCircle, bg, step(0.0, d));
        
        //再方形， 把之前画好的图形，即color的颜色，当作mix的背景处理即可
        center = float2(0.75, 0.75);
        r = 0.25;
        d = sdfSquare(uv, center, r);
        float3 colorSquare = float3(0.8, 0.3, 0.2);
        color = mix(colorSquare, color, step(0.0, d));
        
        return color;
    }
    
    
    //绘制圆角矩形 通过进度更改圆角的弧度
    float4 drawScreen2(float2 uv, float progress) {
        float4 color = float4(0.0, 0.0, 0.0, 0.0);
        float4 bgColor = float4(1.0, 1.0, 1.0, 1.0);
        
        float d = sdRoundedBox(uv, float2(0.25, 0.25), float2(0.5), progress * 0.1);
        
        
        float alpha = min(d, 1.0);
        alpha = max(alpha, 0.0);
        
        float3 c = color.rgb * alpha + bgColor.rgb * (1.0 - alpha);
        
        return float4(c, 1.0);
    }
    
    fragment float4 shape_fragment
    (
     MatrixVertexOut in [[ stage_in ]],
     texture2d<float> texture [[ texture(0) ]],
     constant float& progress[[ buffer(1) ]],
     constant float& ratio[[ buffer(2) ]],
     sampler sampler [[ sampler(0) ]]
     ){
         float2 uv = in.uv;
         ratio < 1.0 ? uv.y /= ratio : uv.x *= ratio;
         
         return drawScreen2(uv, progress);
     }
}
