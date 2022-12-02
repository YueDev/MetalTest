//
//  TransitionCamera.metal
//  MetalTest
//
//  Created by YUE on 2022/11/23.
//

#include <metal_stdlib>
#include "Model.metal"
using namespace metal;
using namespace Model;


namespace Transition3D01 {
    
    //uniform float persp;// 透视= 左侧图片错切缩小程度0.7
    //uniform float unzoom;// 缩放程度= 0.3
    //uniform float reflection;// 底部的倒影= 0.4
    //uniform float floating;// 与底部倒影的距离 ,有一种漂浮的感觉= 3.0
    constant float persp = 0.7;
    constant float unzoom = 0.3;
    constant float reflection = 0.4;
    constant float floating = 3.0;
    
    float2 project (float2 p) {
        float2 rtn= p * float2(1.0, (1.0-floating/100.)) ;
        rtn.y=2.-rtn.y;
        return rtn;
    }
    
    bool inBounds (float2 p) {
        return all(float2(0.0) < p) && all(p < float2(1.0));
    }
    
    float4 getToColor(float2 uv, texture2d<float> inTexture2, sampler sampler){
        return inTexture2.sample(sampler, uv);
    }
    float4 getFromColor(float2 uv, texture2d<float> inTexture1, sampler sampler){
        return inTexture1.sample(sampler, uv);
        
    }

    float4 bgColor (float2 p, float2 pfr, float2 pto, texture2d<float> inTexture1, texture2d<float> inTexture2,sampler sampler) {
        float4 c = float4(0.0, 0.0, 0.0, 1.0);
        pfr = project(pfr);
        if (inBounds(pfr)) {
            c += mix(float4(0.0), getFromColor(pfr, inTexture1, sampler), reflection * mix(0.0, 1.0, pfr.y));
        }
        pto = project(pto);
        if (inBounds(pto)) {
            c += mix(float4(0.0), getToColor(pto, inTexture2, sampler), reflection * mix(0.0, 1.0, pto.y));
        }
        return c;
    }
    
    float2 xskew (float2 p, float persp, float center) {
        float x = mix(p.x, 1.0-p.x, center);
        return (
        (
         float2(x, (p.y - 0.5*(1.0-persp) * x) / (1.0+(persp-1.0)*x))
        - float2(0.5 - abs(center - 0.5), 0.0)
        )
        * float2(0.5 / abs(center - 0.5) * (center<0.5 ? 1.0 : -1.0), 1.0)
        + float2(center<0.5 ? 0.0 : 1.0, 0.0)
        );
    }
    
    
    
    kernel void t3d_01
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
         
         float newProgress = 1.0-progress;
         float uz = unzoom * 2.0*(0.5-abs(newProgress - 0.5));
         float2 p = -uz*0.5+(1.0+uz) * uv;
         float2 fromP = xskew(
         (p - float2(newProgress, 0.0)) / float2(1.0-newProgress, 1.0),
         1.0-mix(newProgress, 0.0, persp),
         0.0
         );
         float2 toP = xskew(
         p / float2(newProgress, 1.0),
         mix(pow(newProgress, 2.0), 1.0, persp),
         1.0
         );
         // FIXME avoid branching might help perf!
         float4 out;
         if (inBounds(fromP)) {
             out = getToColor(fromP, inTexture2, sampler);
         } else if (inBounds(toP)) {
             out = getFromColor(toP, inTexture1, sampler);
         } else{
             out = bgColor(uv, toP, fromP, inTexture1, inTexture2, sampler);
         }
         outTexture.write(out, grid);
     }
}

namespace Transition3D02 {
    
    
    
    
    
    kernel void t3d_02
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
         uv.x = 1.0 - uv.x;
         
         
         float newProgress = 1.0-progress;
         float uz = Transition3D01::unzoom * 2.0*(0.5-abs(newProgress - 0.5));
         float2 p = -uz*0.5+(1.0+uz) * uv;
         float2 fromP = Transition3D01::xskew(
         (p - float2(newProgress, 0.0)) / float2(1.0-newProgress, 1.0),
                              1.0-mix(newProgress, 0.0, Transition3D01::persp),
         0.0
         );
         float2 toP = Transition3D01::xskew(
         p / float2(newProgress, 1.0),
                            mix(pow(newProgress, 2.0), 1.0, Transition3D01::persp),
         1.0
         );
         // FIXME avoid branching might help perf!
         float4 out;
         if (Transition3D01::inBounds(fromP)) {
             out = Transition3D01::getToColor(fromP, inTexture2, sampler);
         } else if (Transition3D01::inBounds(toP)) {
             out = Transition3D01::getFromColor(toP, inTexture1, sampler);
         } else{
             out = Transition3D01::bgColor(uv, toP, fromP, inTexture1, inTexture2, sampler);
         }
         outTexture.write(out, grid);
     }
}