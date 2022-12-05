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


namespace Transition3D04 {
    
    //uniform float reflection;//反射 = 0.4
    //uniform float perspective;//透视 = 0.2
    //uniform float depth;//深度 = 3.0
    constant float reflection = 0.4;
    constant float perspective = 0.2;
    constant float depth = 3.0;
    
    constant const float4 black = float4(0.0, 0.0, 0.0, 1.0);
    constant const float2 boundMin = float2(0.0, 0.0);
    constant const float2 boundMax = float2(1.0, 1.0);
    
    bool inBounds (float2 p) {
        return all(boundMin < p) && all(p < boundMax);
    }
    
    float2 project (float2 p) {
        float2 rtn= p * float2(1.0, (1.0-depth/100.)) ;
        rtn.y=2.-rtn.y;
        return rtn;
    }
    
    float4 bgColor (float2 p, float2 pfr, float2 pto, texture2d<float> inTexture1, texture2d<float> inTexture2,sampler sampler) {
        float4 c = black;
        pfr = project(pfr);
        if (inBounds(pfr)) {
            c += mix(black, Transition3D01::getFromColor(pfr, inTexture1, sampler), reflection * mix(0.0, 1.0, pfr.y));
        }
        pto = project(pto);
        if (inBounds(pto)) {
            c += mix(black, Transition3D01::getToColor(pto, inTexture2, sampler), reflection * mix(0.0,1.0, pto.y));
        }
        return c;
    }
    
    
    kernel void t3d_04
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
         
         float2 p = uv;
         float2 pfr, pto = float2(-1.);
         
         float size = mix(1.0, depth, progress);
         float persp = perspective * progress;
         pfr = (p + float2(-0.0, -0.5)) * float2(size/(1.0-perspective*progress), size/(1.0-size*persp*p.x)) + float2(0.0, 0.5);
         
         size = mix(1.0, depth, 1.-progress);
         persp = perspective * (1.-progress);
         
         pto = (p + float2(-1.0, -0.5)) * float2(size/(1.0-perspective*(1.0-progress)), size/(1.0-size*persp*(0.5-p.x))) + float2(1.0, 0.5);
         
         float4 out;
         
         if (progress < 0.5) {
             if (inBounds(pfr)) {
                 out = Transition3D01::getFromColor(pfr, inTexture1, sampler);
                 outTexture.write(out, grid);
                 return;
             }
             if (inBounds(pto)) {
                 out = Transition3D01::getToColor(pto, inTexture2, sampler);
                 outTexture.write(out, grid);
                 return;
             }
         }
         if (inBounds(pto)) {
             out = Transition3D01::getToColor(pto, inTexture2, sampler);
             outTexture.write(out, grid);
             return;
         }
         if (inBounds(pfr)) {
             out = Transition3D01::getFromColor(pfr, inTexture1, sampler);
             outTexture.write(out, grid);
             return;
         }
         out = bgColor(p, pfr, pto, inTexture1, inTexture2, sampler);
         outTexture.write(out, grid);
     }
}

namespace Transition3D05 {
    
    constant float MIN_AMOUNT = -0.16;
    constant float MAX_AMOUNT = 1.5;
    constant float PI = 3.1415926;
    constant float scale = 512.0;
    constant float sharpness = 3.0;
    constant float cylinderRadius = 1.0 / PI / 2.0;
    
    
    
    
    float3 hitPoint(float hitAngle, float yc, float3 point, float3x3 rrotation)
    {
        float hitPoint = hitAngle / (2.0 * PI);
        point.y = hitPoint;
        return rrotation * point;
    }
    
    float4 antiAlias(float4 color1, float4 color2, float distanc)
    {
        distanc *= scale;
        if (distanc < 0.0) return color2;
        if (distanc > 2.0) return color1;
        float dd = pow(1.0 - distanc / 2.0, sharpness);
        return ((color2 - color1) * dd) + color1;
    }
    
    float distanceToEdge(float3 point)
    {
        float dx = abs(point.x > 0.5 ? 1.0 - point.x : point.x);
        float dy = abs(point.y > 0.5 ? 1.0 - point.y : point.y);
        if (point.x < 0.0) dx = -point.x;
        if (point.x > 1.0) dx = point.x - 1.0;
        if (point.y < 0.0) dy = -point.y;
        if (point.y > 1.0) dy = point.y - 1.0;
        if ((point.x < 0.0 || point.x > 1.0) && (point.y < 0.0 || point.y > 1.0)) return sqrt(dx * dx + dy * dy);
        return min(dx, dy);
    }
    
    float4 seeThrough(float yc, float2 p, float3x3 rotation, float3x3 rrotation, texture2d<float> inTexture1, texture2d<float> inTexture2, sampler sampler, float amount, float cylinderCenter, float cylinderAngle)
    {
        float hitAngle = PI - (acos(yc / cylinderRadius) - cylinderAngle);
        float3 point = hitPoint(hitAngle, yc, rotation * float3(p, 1.0), rrotation);
        if (yc <= 0.0 && (point.x < 0.0 || point.y < 0.0 || point.x > 1.0 || point.y > 1.0))
        {
            return Transition3D01::getToColor(p, inTexture2, sampler);
        }
        
        if (yc > 0.0) return Transition3D01::getFromColor(p, inTexture1, sampler);
        
        float4 color = Transition3D01::getFromColor(point.xy, inTexture1, sampler);
        float4 tcolor = float4(0.0);
        
        return antiAlias(color, tcolor, distanceToEdge(point));
    }
    
    float4 seeThroughWithShadow(float yc, float2 p, float3 point, float3x3 rotation, float3x3 rrotation, texture2d<float> inTexture1, texture2d<float> inTexture2, sampler sampler, float amount, float cylinderCenter, float cylinderAngle)
    {
        float shadow = distanceToEdge(point) * 30.0;
        shadow = (1.0 - shadow) / 3.0;
        
        if (shadow < 0.0) shadow = 0.0; else shadow *= amount;
        
        float4 shadowColor = seeThrough(yc, p, rotation, rrotation, inTexture1, inTexture2, sampler, amount, cylinderCenter, cylinderAngle);
        shadowColor.r -= shadow;
        shadowColor.g -= shadow;
        shadowColor.b -= shadow;
        
        return shadowColor;
    }
    
    float4 backside(float yc, float3 point, texture2d<float> inTexture1, sampler sampler)
    {
        float4 color = Transition3D01::getFromColor(point.xy, inTexture1, sampler);
        float gray = (color.r + color.b + color.g) / 15.0;
        gray += (8.0 / 10.0) * (pow(1.0 - abs(yc / cylinderRadius), 2.0 / 10.0) / 2.0 + (5.0 / 10.0));
        color.rgb = float3(gray);
        return color;
    }
    
    float4 behindSurface(float2 p, float yc, float3 point, float3x3 rrotation, texture2d<float> inTexture2, sampler sampler, float amount, float cylinderCenter, float cylinderAngle)
    {
        float shado = (1.0 - ((-cylinderRadius - yc) / amount * 7.0)) / 6.0;
        shado *= 1.0 - abs(point.x - 0.5);
        
        yc = (-cylinderRadius - cylinderRadius - yc);
        
        float hitAngle = (acos(yc / cylinderRadius) + cylinderAngle) - PI;
        point = hitPoint(hitAngle, yc, point, rrotation);
        
        if (yc < 0.0 && point.x >= 0.0 && point.y >= 0.0 && point.x <= 1.0 && point.y <= 1.0 && (hitAngle < PI || amount > 0.5))
        {
            shado = 1.0 - (sqrt(pow(point.x - 0.5, 2.0) + pow(point.y - 0.5, 2.0)) / (71.0 / 100.0));
            shado *= pow(-yc / cylinderRadius, 3.0);
            shado *= 0.5;
        }
        else
        {
            shado = 0.0;
        }
        return float4(Transition3D01::getToColor(p, inTexture2, sampler).rgb - shado, 1.0);
    }
    
    
    kernel void t3d_05
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
         
         if (progress == 0) {
             float4 out = Transition3D01::getFromColor(uv, inTexture1, sampler);
             outTexture.write(out, grid);
             return;
         }
         
         float amount = 0;
         float cylinderCenter = 0;
         float cylinderAngle = 0;
         
         amount = progress * (MAX_AMOUNT - MIN_AMOUNT) + MIN_AMOUNT;
         cylinderCenter = amount;
         cylinderAngle = 2.0 * PI * amount;
         
         float2 p = uv;
         const float angle = 100.0 * PI / 180.0;
         float c = cos(-angle);
         float s = sin(-angle);
         
         float3x3 rotation = float3x3(c, s, 0,
                                      -s, c, 0,
                                      -0.801, 0.8900, 1
                                      );
         c = cos(angle);
         s = sin(angle);
         
         float3x3 rrotation = float3x3(c, s, 0,
                                       -s, c, 0,
                                       0.98500, 0.985, 1
                                       );
         
         float3 point = rotation * float3(p, 1.0);
         
         float yc = point.y - cylinderCenter;
         
         float4 out;
         if (yc < -cylinderRadius)
         {
             // Behind surface
             out = behindSurface(p, yc, point, rrotation, inTexture2, sampler, amount, cylinderCenter, cylinderAngle);
             outTexture.write(out, grid);
             return;
         }
         if (yc > cylinderRadius)
         {
             // Flat surface
             out = Transition3D01::getFromColor(p, inTexture1, sampler);
             outTexture.write(out, grid);
             return;
         }
         
         float hitAngle = (acos(yc / cylinderRadius) + cylinderAngle) - PI;
         
         float hitAngleMod = fmod(hitAngle, 2.0 * PI);
         if ((hitAngleMod > PI && amount < 0.5) || (hitAngleMod > PI/2.0 && amount < 0.0))
         {
             out = seeThrough(yc, p, rotation, rrotation, inTexture1, inTexture2, sampler, amount, cylinderCenter, cylinderAngle);
             outTexture.write(out, grid);
             return;
         }
         
         point = hitPoint(hitAngle, yc, point, rrotation);

         if (point.x < 0.0 || point.y < 0.0 || point.x > 1.0 || point.y > 1.0)
         {
             out = seeThroughWithShadow(yc, p, point, rotation, rrotation, inTexture1, inTexture2, sampler, amount, cylinderCenter, cylinderAngle);
             outTexture.write(out, grid);
             return;
         }
         
         float4 color = backside(yc, point, inTexture1, sampler);
         
         float4 otherColor;
         if (yc < 0.0)
         {
             float shado = 1.0 - (sqrt(pow(point.x - 0.5, 2.0) + pow(point.y - 0.5, 2.0)) / 0.71);
             shado *= pow(-yc / cylinderRadius, 3.0);
             shado *= 0.5;
             otherColor = float4(0.0, 0.0, 0.0, shado);
         }
         else
         {
             otherColor = Transition3D01::getFromColor(p, inTexture1, sampler);
         }
         
         color = antiAlias(color, otherColor, cylinderRadius - abs(yc));

         float4 cl = seeThroughWithShadow(yc, p, point, rotation, rrotation, inTexture1, inTexture2, sampler, amount, cylinderCenter, cylinderAngle);
         float dist = distanceToEdge(point);
         
         out = antiAlias(color, cl, dist);
         outTexture.write(out, grid);
         
     }
    
}
