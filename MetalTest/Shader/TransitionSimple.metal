#include <metal_stdlib>
#include "Model.metal"
using namespace metal;
using namespace Model;

namespace TransitionSimple {
    
    vertex VertexOut simple_vertex_render
    (
     VertexIn in [[ stage_in ]],
     constant float2& vertexScale [[ buffer(1) ]]
     ) {
         VertexOut out;
         out.position = float4(in.positionAndUV.xy * vertexScale, 0.0, 1.0);
         out.uv = in.positionAndUV.zw;
         return out;
     }
    
    fragment float4 simple_fragment_render
    (
     VertexOut in [[ stage_in ]],
     texture2d<float> texture [[texture(0)]],
     sampler sampler [[ sampler(0) ]]
     ){
         float4 out = texture.sample(sampler, in.uv);
         return out;
     }
    
    
    kernel void simple_mix_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 texColor1 = inTexture1.sample(sampler, uv);
         float4 texColor2 = inTexture2.sample(sampler, uv);
         
         float4 out = mix(texColor1, texColor2, progress);
         
         outTexture.write(out, grid);
     }
    
    
    kernel void simple_slide_left_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float2 f = fract(uv + float2(progress, 0.0));
         
         float4 out1 = inTexture1.sample(sampler, f);
         float4 out2 = inTexture2.sample(sampler, f);
         
         float4 out =  mix(out1, out2, step(1.0 - uv.x, progress));
         outTexture.write(out, grid);
     }
    
    
    kernel void simple_slide_right_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float2 f = fract(uv - float2(progress, 0.0));
         
         float4 out1 = inTexture1.sample(sampler, f);
         float4 out2 = inTexture2.sample(sampler, f);
         
         float4 out =  mix(out1, out2, step(uv.x, progress));
         outTexture.write(out, grid);
     }
    
    
    kernel void simple_slide_up_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float2 f = fract(uv + float2(0.0, progress));
         
         float4 out1 = inTexture1.sample(sampler, f);
         float4 out2 = inTexture2.sample(sampler, f);
         
         float4 out =  mix(out1, out2, step(1.0 - uv.y, progress));
         outTexture.write(out, grid);
     }
    
    
    kernel void simple_slide_down_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float2 f = fract(uv - float2(0.0, progress));
         
         float4 out1 = inTexture1.sample(sampler, f);
         float4 out2 = inTexture2.sample(sampler, f);
         
         float4 out =  mix(out1, out2, step(uv.y, progress));
         outTexture.write(out, grid);
     }
    
    
    kernel void simple_cover_left_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 out1 = inTexture1.sample(sampler, uv);
         float4 out2 = inTexture2.sample(sampler, uv);
         
         float4 out =  mix(out1, out2, step(uv.x, progress));
         outTexture.write(out, grid);
     }
    
    kernel void simple_cover_right_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 out1 = inTexture1.sample(sampler, uv);
         float4 out2 = inTexture2.sample(sampler, uv);
         
         float4 out =  mix(out1, out2, step(1.0 - uv.x, progress));
         outTexture.write(out, grid);
     }
    
    kernel void simple_cover_up_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 out1 = inTexture1.sample(sampler, uv);
         float4 out2 = inTexture2.sample(sampler, uv);
         
         float4 out =  mix(out1, out2, step(1.0 - uv.y, progress));
         outTexture.write(out, grid);
     }
    
    kernel void simple_cover_down_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 out1 = inTexture1.sample(sampler, uv);
         float4 out2 = inTexture2.sample(sampler, uv);
         
         float4 out =  mix(out1, out2, step(uv.y, progress));
         outTexture.write(out, grid);
     }
    
    //=======================心形===================================
    
    float inHeart (float2 p, float2 center, float size, float ratio) {
        if (size==0.0) return 0.0;
        p.y=1.-p.y;
        
        float2 change=(p-center)*0.9;
        if(ratio>1.0){
            change.y=change.y/ratio;
        }else{
            change.x=change.x*ratio;
        }
        p=center+change;
        
        float showmax=1.6;
        float2 o = (p-center)/(showmax*size);
        float a = o.x*o.x+o.y*o.y-0.3;
        return step(a*a*a, o.x*o.x*o.y*o.y*o.y);
    }
    
    kernel void simple_heart_out_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ) {
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 texColor1 = inTexture1.sample(sampler, uv);
         float4 texColor2 = inTexture2.sample(sampler, uv);
         
         float4 out = mix(texColor1,texColor2,inHeart(uv, float2(0.5, 0.45), progress, ratio));
         outTexture.write(out, grid);
     }
    
    //============================圆形==============================================
    
    kernel void simple_circle_out_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ) {
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 texColor1 = inTexture1.sample(sampler, uv);
         float4 texColor2 = inTexture2.sample(sampler, uv);
         
         float2 ratio2 = ratio > 1.0 ? float2(1.0, 1.0 / ratio) / ratio : float2(ratio, 1.0);
         float s = pow(0.5 + (progress - 0.5) * 0.8, 3.0);
         float dist = length((uv - 0.5) * ratio2);
         
         float4 out = mix(texColor2, texColor1, step(s, dist));
         outTexture.write(out, grid);
     }
    
    //============================放大缩小==============================================
    

    
    float Exponential_easeInOut(float begin, float change, float duration, float time) {
        if (time == 0.0)
            return begin;
        else if (time == duration)
            return begin + change;
        time = time / (duration / 2.0);
        if (time < 1.0)
            return change / 2.0 * pow(2.0, 10.0 * (time - 1.0)) + begin;
        return change / 2.0 * (-pow(2.0, -10.0 * (time - 1.0)) + 2.0) + begin;
    }
    
    float Sinusoidal_easeInOut(float begin, float change, float duration, float time) {
        return -change / 2.0 * (cos(PI * time / duration) - 1.0) + begin;
    }
    
    float rand(float2 co) {
        return fract(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
    }
    
    
    kernel void simple_zoom_out_in_kernel
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ) {
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float2 newUV = uv;
         
         if(progress<0.5)
             newUV = 0.5 + (newUV - 0.5) * (0.2 + (0.5 - progress) * 1.6);
         float2 center =float2(0.5);
         float dissolve = Exponential_easeInOut(0.0, 1.0, 1.0, progress);
         float strength = 0.4;
         strength = Sinusoidal_easeInOut(0.0, strength , 0.5, progress);
         
         float3 color = float3(0.0);
         float total = 0.0;
         float2 toCenter = center - newUV;
         
         float offset = rand(uv);
         
         float num = 10.0;
         for (float t = 0.0; t <= num; t++) {
             float percent = (t + offset) / num;
             float weight = 4.0 * (percent - percent * percent);
             
             //opengl fun crossfade in t1004_fragment.glsl
             float3 crossFade;
             float2 texUV = newUV + toCenter * percent * strength;
             if(progress < 0.5) {
                 float4 texColor1 = inTexture1.sample(sampler, texUV);
                 crossFade =  mix(texColor1.rgb, float3(0.1), dissolve);
             }
             else {
                 float4 texColor2 = inTexture2.sample(sampler, texUV);
                 crossFade =  mix(float3(0.1), texColor2.rgb, dissolve);
             }
             
             color += crossFade * weight;
             total += weight;
         }
         
         float4 out = float4(color / total, 1.0);
         
         
         outTexture.write(out, grid);
     }
    
}
