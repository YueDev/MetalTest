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

namespace TransitionCamera01 {
    
    float Linear_ease(float begin, float change, float duration, float time) {
        return change * time / duration + begin;
    }
    
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
    
    float rand (float2 co) {
        return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
    }
    
    
    float2 doroate(float2 c2, float roate, float scale, float ratio){
        //计算旋转角度
        float2 uv2  =c2-0.5;
        if(ratio>1.0){
            uv2.x=uv2.x*ratio;
        }else{
            uv2.y=uv2.y/ratio;
        }
        float c = cos(roate);
        float s = sin(roate);
        float dx2 = uv2.x*c+uv2.y*s;
        float dy2 = -uv2.x*s+uv2.y*c;
        if(ratio>1.0){
            dx2=dx2/ratio;
        }else{
            dy2=dy2*ratio;
        }
        float2 rtn=float2(0.5+dx2/scale,0.5+dy2/scale);
        return rtn;
    }
    
    
    
    kernel void camera_01
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
         
         float rotations=1.0; // 旋转多少圈  1;
         float scale=3.0; // 扩大的比例= 8;
         const float4 backColor= float4(0.15, 0.15, 0.15, 1.0);
         
         
         float angle = 2.0 * PI * rotations * progress;
         float currentScale = mix(scale, 1.0, 2.0 * abs(progress - 0.5));
         
         uv = doroate(uv,angle,currentScale,ratio);
         
         
         if (uv.x < 0.0 || uv.x > 1.0 ||
             uv.y < 0.0 || uv.y > 1.0){
             outTexture.write(backColor, grid);
             return;
         } else {
             // Linear interpolate center across center half of the image
             float2 center = float2(0.5);
             float dissolve = Exponential_easeInOut(0.0, 1.0, 1.0, progress);
             // Mirrored sinusoidal loop. 0->strength then strength->0
             float strength = Sinusoidal_easeInOut(0.0, 0.4, 0.5, progress);
             
             float3 color = float3(0.0);
             float total = 0.0;
             float2 toCenter = center - uv;
             /* randomize the lookup values to hide the fixed number of samples */
             float offset = rand(originUV);
             
             float num=10.0;
             for (float t = 0.0; t <= num; t++) {
                 float percent = (t + offset) / num;
                 float weight = 4.0 * (percent - percent * percent);
                 float2 newUV = uv + toCenter * percent * strength;
                 
                 float3 color1 = inTexture1.sample(sampler, newUV).rgb;
                 float3 color2 = inTexture2.sample(sampler, newUV).rgb;
                 color += mix(color1, color2, dissolve) * weight;
                 total += weight;
             }
             float4 out = float4(color / total, 1.0);
             outTexture.write(out, grid);
         }
     }
}

namespace TransitionCamera02 {
    
    kernel void camera_02
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
         
         float2 center = float2(TransitionCamera01::Linear_ease(0.25, 0.5, 1.0, progress), 0.5);
         float dissolve = TransitionCamera01::Exponential_easeInOut(0.0, 1.0, 1.0, progress);
         
         float strength = TransitionCamera01::Sinusoidal_easeInOut(0.0, 0.4, 0.5, progress);
         
         float3 color = float3(0.0);
         float total = 0.0;
         float2 toCenter = center - uv;
         
         float offset = TransitionCamera01::rand(originUV);
         
         float num=10.0;
         for (float t = 0.0; t <= num; t++) {
             float percent = (t + offset) / num;
             float weight = 4.0 * (percent - percent * percent);
             float2 newUV = uv + toCenter * percent * strength;
             
             float3 color1 = inTexture1.sample(sampler, newUV).rgb;
             float3 color2 = inTexture2.sample(sampler, newUV).rgb;
             color += mix(color1, color2, dissolve) * weight;
             total += weight;
         }
         float4 out = float4(color / total, 1.0);
         outTexture.write(out, grid);
     }
}


namespace TransitionCamera03 {
    
    
    kernel void camera_03
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
         float amplitude = 100.0;
         float speed = 50.0;
         
         float2 dir = uv - float2(0.5);
         float dist = length(dir);
         float2 offset = dir * (sin(progress * dist * amplitude - progress * speed) + .5) / 30.0;
         
         float4 color1 = inTexture1.sample(sampler, uv + offset);
         float4 color2 = inTexture2.sample(sampler, uv);
         float4 out = mix(color1, color2, smoothstep(0.2, 1.0, progress));
         outTexture.write(out, grid);
     }
}

namespace TransitionCamera04 {
    
    constant float zoom = 0.88;
    // Corner radius as a fraction of the image height
    //uniform float corner_radius;// = 0.22
    constant float corner_radius = 0.22;
    
    constant const float4 black = float4(0.0, 0.0, 0.0, 1.0);
    constant const float2 c00 = float2(0.0, 0.0);// the four corner points
    constant const float2 c01 = float2(0.0, 1.0);
    constant const float2 c11 = float2(1.0, 1.0);
    constant const float2 c10 = float2(1.0, 0.0);
    
    
    float4 getToColor(float2 uv, texture2d<float> inTexture2, sampler sampler){
        return inTexture2.sample(sampler, uv);
    }
    float4 getFromColor(float2 uv, texture2d<float> inTexture1, sampler sampler){
        return inTexture1.sample(sampler, uv);
        
    }
    
    
    bool in_corner(float2 p, float2 corner, float2 radius) {
        float2 axis = (c11 - corner) - corner;
        p = p - (corner + axis * radius);
        p *= axis / radius;
        return (p.x > 0.0 && p.y > -1.0) || (p.y > 0.0 && p.x > -1.0) || dot(p, p) < 1.0;
    }
    
    bool test_rounded_mask(float2 p, float2 corner_size) {
        return
        in_corner(p, c00, corner_size) &&
        in_corner(p, c01, corner_size) &&
        in_corner(p, c10, corner_size) &&
        in_corner(p, c11, corner_size);
    }
    
    float4 screen(float4 a, float4 b) {
        return 1.0 - (1.0 - a) * (1.0 -b);
    }
    
    float4 unscreen(float4 c) {
        return 1.0 - sqrt(1.0 - c);
    }
    
    float4 sample_with_corners_from(float2 p, float2 corner_size, texture2d<float> inTexture1, sampler sampler) {
        p = (p - 0.5) / zoom + 0.5;
        if (!test_rounded_mask(p, corner_size)) {
            return black;
        }
        return unscreen(getFromColor(p, inTexture1, sampler));
    }
    
    float4 sample_with_corners_to(float2 p, float2 corner_size, texture2d<float> inTexture2, sampler sampler) {
        p = (p - 0.5) / zoom + 0.5;
        if (!test_rounded_mask(p, corner_size)) {
            return black;
        }
        return unscreen(getToColor(p, inTexture2, sampler));
    }
    
    float4 simple_sample_with_corners_from(float2 p, float2 corner_size, float zoom_amt, texture2d<float> inTexture1, sampler sampler) {
        p = (p - 0.5) / (1.0 - zoom_amt + zoom * zoom_amt) + 0.5;
        if (!test_rounded_mask(p, corner_size)) {
            return black;
        }
        return getFromColor(p, inTexture1, sampler);
    }
    
    float4 simple_sample_with_corners_to(float2 p, float2 corner_size, float zoom_amt, texture2d<float> inTexture2, sampler sampler) {
        p = (p - 0.5) / (1.0 - zoom_amt + zoom * zoom_amt) + 0.5;
        if (!test_rounded_mask(p, corner_size)) {
            return black;
        }
        return getToColor(p, inTexture2, sampler);
    }
    
    
    
    float3x3 rotate2d(float angle, float ratio) {
        float s = sin(angle);
        float c = cos(angle);
        return float3x3(
                        c, s, 0.0,
                        -s, c, 0.0,
                        0.0, 0.0, 1.0);
    }
    
    float3x3 translate2d(float x, float y) {
        return float3x3(
                        1.0, 0.0, 0,
                        0.0, 1.0, 0,
                        -x, -y, 1.0);
    }
    
    float3x3 scale2d(float x, float y) {
        return float3x3(
                        x, 0.0, 0,
                        0.0, y, 0,
                        0, 0, 1.0);
    }
    
    float4 get_cross_rotated(float3 p3, float angle, float2 corner_size, float ratio, texture2d<float> inTexture1, sampler sampler) {
        angle = angle * angle;
        angle /= 2.4;
        
        float3x3 center_and_scale = translate2d(-0.5, -0.5) * scale2d(1.0, ratio);
        float3x3 unscale_and_uncenter = scale2d(1.0, 1.0/ratio) * translate2d(0.5, 0.5);
        float3x3 slide_left = translate2d(-2.0, 0.0);
        float3x3 slide_right = translate2d(2.0, 0.0);
        float3x3 rotate = rotate2d(angle, 1.2);
        
        float3x3 op_a = center_and_scale * slide_right * rotate * slide_left * unscale_and_uncenter;
        float3x3 op_b = center_and_scale * slide_left * rotate * slide_right * unscale_and_uncenter;
        
        float4 a = sample_with_corners_from((op_a * p3).xy, corner_size, inTexture1, sampler);
        float4 b = sample_with_corners_from((op_b * p3).xy, corner_size, inTexture1, sampler);
        
        return screen(a, b);
    }
    
    float4 get_cross_masked(float3 p3, float angle, float2 corner_size, float ratio, texture2d<float> inTexture2, sampler sampler) {
        angle = 1.0 - angle;
        angle = angle * angle;// easing
        angle /= 2.4;
        
        float4 img;
        
        float3x3 center_and_scale = translate2d(-0.5, -0.5) * scale2d(1.0, ratio);
        float3x3 unscale_and_uncenter = scale2d(1.0 / zoom, 1.0 / (zoom * ratio)) * translate2d(0.5, 0.5);
        //    float my=0.;
        //    if(ratio<1.0){
        //        my=(2.0-ratio)*(0.9-progress);
        //    }
        float3x3 slide_left = translate2d(-2.0, 0.);
        float3x3 slide_right = translate2d(2.0, 0.);
        float3x3 rotate = rotate2d(angle, ratio);
        
        float3x3 op_a = center_and_scale * slide_right * rotate * slide_left * unscale_and_uncenter;
        float3x3 op_b = center_and_scale * slide_left * rotate * slide_right * unscale_and_uncenter;
        
        bool mask_a = test_rounded_mask((op_a * p3).xy, corner_size);
        bool mask_b = test_rounded_mask((op_b * p3).xy, corner_size);
        
        if (mask_a || mask_b) {
            img = sample_with_corners_to(p3.xy, corner_size, inTexture2, sampler);
            return screen(mask_a ? img : black, mask_b ? img : black);
        } else {
            return black;
        }
    }
    
    
    
    kernel void camera_04
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
         float a;
         float3 p3 = float3(p.xy, 1.0);
         
         float2 corner_size = float2(corner_radius/ratio, corner_radius);
         
         if (progress <= 0.0) {
             // 0.0: start with the base frame always
             float4 out = getFromColor(p, inTexture1, sampler);
             outTexture.write(out, grid);
             return;
         } else if (progress < 0.1) {
             // 0.0-0.1: zoom out and add rounded corners
             a = progress / 0.1;
             float4 out = simple_sample_with_corners_from(p, corner_size * a, a, inTexture1, sampler);
             outTexture.write(out, grid);
             return;
         } if (progress < 0.48) {
             // 0.1-0.48: Split original image apart
             a = (progress - 0.1)/0.38;
             if (ratio<1.){
                 a =a+ a * (1./ratio-1.)/2.;
             }
             float4 out = get_cross_rotated(p3, a, corner_size, ratio, inTexture1, sampler);
             outTexture.write(out, grid);
             return;
         } else if (progress < 0.9) {
             a = (progress - 0.52)/0.38;
             float4 out = get_cross_masked(p3, a, corner_size, ratio, inTexture2, sampler);
             outTexture.write(out, grid);
             return;
         }  if (progress < 1.0) {
             // zoom out and add rounded corners
             a = (1.0 - progress) / 0.1;
             float4 out = simple_sample_with_corners_to(p, corner_size * a, a, inTexture2, sampler);
             outTexture.write(out, grid);
             return;
         } else {
             float4 out = getToColor(p, inTexture2, sampler);
             outTexture.write(out, grid);
             return;
         }
     }
}


namespace TransitionCamera05 {
    
    
    float Rand(float2 v) {
        return fract(sin(dot(v.xy ,float2(12.9898,78.233))) * 43758.5453);
    }
    
    float2 Rotate(float2 v, float a) {
        float2x2 rm = float2x2(cos(a), -sin(a),
                               sin(a), cos(a));
        return rm * v;
    }
    
    float CosInterpolation(float x) {
        return -cos(x*PI)/2.+.5;
    }
    
    kernel void camera_05
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ) {
         int endx = 2; // = 2
         int endy = -1; // = -1
         
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float2 p = uv.xy - 0.5;
         float2 rp = p;
         float rpr = (progress*2.-1.);
         float z = -(rpr*rpr*2.) + 3.;
         float az = abs(z);
         rp *= az;
         float cosp = CosInterpolation(progress);
         rp += mix(float2(.5, .5), float2(float(endx) + .5, float(endy) + .5), cosp * cosp);
         float2 mrp = fmod(rp, 1.);
         float2 crp = rp;


         bool onEnd = int(floor(crp.x))==endx&&int(floor(crp.y))==endy;
         
         //去掉了角度 因为模仿的repeat 可能和原设计不太一样
//         if(!onEnd) {
//             //角度在这里调， 最后的pi就是 180度 也就是有几个图像会是倒着的
//             float ang = float(int(Rand(floor(crp))*4.)) *PI;
//             mrp = float2(.5) + Rotate(mrp-float2(.5), ang);
//         }
         
         //原逻辑好像是gl repeat，这里的sampler是clamp2edge 这里模仿下repeat
         if (mrp.x < 0.0) {
             mrp.x += 1.0;
         }
         
         
         if (mrp.y < 0.0) {
             mrp.y += 1.0;
         }
         
         if (mrp.x > 1.0) {
             mrp.x -= 1.0;
         }
         
         if (mrp.y > 1.0) {
             mrp.y -= 1.0;
         }
         
         if(onEnd || Rand(floor(crp)) > 0.5) {
             float4 out = TransitionCamera04::getToColor(mrp, inTexture2, sampler);
             outTexture.write(out, grid);
             return;
         } else {
             float4 out = TransitionCamera04::getFromColor(mrp, inTexture1, sampler);
             outTexture.write(out, grid);
             return;
         }
     }
}


