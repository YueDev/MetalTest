//
//  Shader.metal
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

#include <metal_stdlib>
#include "Transition.metal"

using namespace metal;
using namespace Transition;


namespace TransitionEffect {
    
    // 效果的四个
    // android:  tran_test/8/t_line.glsl
    
    float4 getFromColor(float2 uv, texture2d<float> inTexture1, sampler sampler){
        return inTexture1.sample(sampler, uv);
    }
    
    float4 getToColor(float2 uv, texture2d<float> inTexture2, sampler sampler){
        return inTexture2.sample(sampler, uv);
    }

    
    float2 zhuanhua(float2 texCoord){
        if(texCoord.x<0.0){
            texCoord.x*=-1.0;
        }
        if(texCoord.y<0.0){
            texCoord.y*=-1.0;
        }
        if(texCoord.x>1.0){
            texCoord.x=2.0-texCoord.x;
        }
        if(texCoord.y>1.0){
            texCoord.y=2.0-texCoord.y;
        }
        return texCoord;
    }
    
    
    float4 crossFade(float2 uv, float progress, texture2d<float> inTexture1, texture2d<float> inTexture2, sampler sampler) {
        uv=zhuanhua(uv);
        return progress<0.5?getFromColor(uv, inTexture1, sampler):getToColor(uv, inTexture2, sampler);
    }
    
    float3 rgbToHsv(float3 c) {
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    float3 hsvToRgb(float3 c) {//convertHsvToRgb
                           float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                           float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
                           return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }
    
    
    //tran_test/8/t_line.glsl
    kernel void transition_effect
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     constant TransitionPara &tranPara [[buffer(0)]],
     constant float& ratio [[ buffer(1) ]],
     constant float& xoff [[ buffer(2) ]],
     constant float& yoff[[ buffer(3) ]],
     constant float& off[[ buffer(4) ]],
     constant float& domove,
     uint2 grid [[thread_position_in_grid]]
     ) {
         float progress = tranPara.percent;
         float2 texCoord = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float3 addmax=float3(0.0,0.0,0.5);

         float pro=domove;
         float domovex = (pro<0.5?pro:pro-1.0);
         
         float domovey = domovex;
         domovex*=xoff;
         domovey*=yoff;
         if(off>0.0){
             texCoord.x+=domovex;
             texCoord.y+=domovey;
         }
         if(ratio<1.0){
             domovex*=ratio;
         }else{
             domovey/=ratio;
         }
         float2 move=float2(domovex, domovey);
         move/=100.0;
         float num=20.0;
         float total=0.0;
         float3 color=float3(0.0);
         for (float t = -num; t <= num; t++) {
             float weight = num-abs(t);
             color += crossFade(texCoord +move*t, progress, inTexture1, inTexture2, sampler).rgb * weight;
             total += weight;
         }
         
         color /= total;
         if(off<0.0){
             float3 hsl=rgbToHsv(color);
             hsl+=addmax*min(pro, 1.0 - pro);
             color=hsvToRgb(hsl);
         }
         
         float4 out = float4(color, 1.0);
         outTexture.write(out, grid);
     }
    
    
}
