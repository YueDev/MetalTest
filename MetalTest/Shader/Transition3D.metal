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
    
    
    float4 getToColor(float2 uv, texture2d<float> inTexture2, sampler sampler){
        return inTexture2.sample(sampler, float2(1.0 - uv.x, uv.y));
    }
    float4 getFromColor(float2 uv, texture2d<float> inTexture1, sampler sampler){
        return inTexture1.sample(sampler, float2(1.0 - uv.x, uv.y));
        
    }
    
    float4 bgColor (float2 p, float2 pfr, float2 pto, texture2d<float> inTexture1, texture2d<float> inTexture2,sampler sampler) {
        float4 c = float4(0.0, 0.0, 0.0, 1.0);
        pfr = Transition3D01::project(pfr);
        if (Transition3D01::inBounds(pfr)) {
            c += mix(float4(0.0), getFromColor(pfr, inTexture1, sampler), Transition3D01::reflection * mix(0.0, 1.0, pfr.y));
        }
        pto = Transition3D01::project(pto);
        if (Transition3D01::inBounds(pto)) {
            c += mix(float4(0.0), getToColor(pto, inTexture2, sampler), Transition3D01::reflection * mix(0.0, 1.0, pto.y));
        }
        return c;
    }
    
    
    
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
         float2 originUV = uv;
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
             out = getToColor(fromP, inTexture2, sampler);
         } else if (Transition3D01::inBounds(toP)) {
             out = getFromColor(toP, inTexture1, sampler);
         } else{
             out = bgColor(originUV, toP, fromP, inTexture1, inTexture2, sampler);
         }
         outTexture.write(out, grid);
     }
}


namespace Transition3D03 {
    
    // uniform float reflection;// 中间底部倒影的反射清 晰度= 0.4
    // uniform float perspective;// 切开图片中间部位的错切程度 透视= 0.4
    // uniform float depth;// 中间出现图片的原始缩放程度 1/depth 深度= 3

    constant float reflection = 0.4;
    constant float perspective = 0.4;
    constant float depth = 3.0;

    constant  float4 black = float4(0.0, 0.0, 0.0, 1.0);
    constant  float2 boundMin = float2(0.0, 0.0);
    constant  float2 boundMax = float2(1.0, 1.0);
    
    bool inBounds (float2 p) {
        return all(boundMin < p) && all(p < boundMax);
    }
    
    float2 project (float2 p) {
        float2 rtn= p * float2(1.0, (1.0-depth/100.)) ;
        rtn.y=2.-rtn.y;
        return rtn;
    }
    
    float4 bgColor (float2 p, float2 pto, texture2d<float> inTexture2, sampler sampler) {
        float4 c = black;
        pto = project(pto);
        if (inBounds(pto)) {
            c += mix(black, Transition3D01::getToColor(pto, inTexture2, sampler), reflection * mix(0.0, 1.0, pto.y));
        }
        return c;
    }
    
    
    kernel void t3d_03
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
         
         float2 pfr = float2(-1.), pto = float2(-1.);
         float middleSlit = 2.0 * abs(uv.x-0.5) - progress;
         if (middleSlit > 0.0) {
             pfr = uv + (uv.x > 0.5 ? -1.0 : 1.0) * float2(0.5*progress, 0.0);
             float d = 1.0/(1.0+perspective*progress*(1.0-middleSlit));
             pfr.y -= d/2.;
             pfr.y *= d;
             pfr.y += d/2.;
         }
         float size = mix(1.0, depth, 1.-progress);
         pto = (uv + float2(-0.5, -0.5)) * float2(size, size) + float2(0.5, 0.5);
         
         float4 out;
         
         if (inBounds(pfr)) {
             out = Transition3D01::getFromColor(pfr, inTexture1, sampler);
         } else if (inBounds(pto)) {
             out = Transition3D01::getToColor(pto, inTexture2, sampler);
         } else {
             out = bgColor(uv, pto, inTexture2, sampler);
         }
         
         outTexture.write(out, grid);
     }
}
