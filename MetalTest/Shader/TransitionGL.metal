//
//
//  TransitionGL.metal
//  MetalTest
//
//  Created by YUE on 2022/12/6.
//
//  Some transition from https://gl-transitions.com/ .
//

#include <metal_stdlib>
#include "Model.metal"
using namespace metal;
using namespace Model;


//https://github.com/gl-transitions/gl-transitions/blob/master/transitions/powerKaleido.glsl
namespace TransitionGL01 {
    
    float4 getToColor(float2 uv, texture2d<float> inTexture2, sampler sampler){
        return inTexture2.sample(sampler, uv);
    }
    float4 getFromColor(float2 uv, texture2d<float> inTexture1, sampler sampler){
        return inTexture1.sample(sampler, uv);
        
    }
    
    constant float rad = 120.; // change this value to get different mirror effects
    constant float deg = rad / 180. * PI;
    constant float scale = 2.0;
    constant float z = 1.5;
    constant float dist = scale / 10.0;
    constant float speed = 5.0;
    
    float2 refl(float2 p,float2 o,float2 n)
    {
        return 2.0*o+2.0*n*dot(p-o,n)-p;
    }
    
    float2 rot(float2 p, float2 o, float a)
    {
        float s = sin(a);
        float c = cos(a);
        return o + float2x2(c, -s, s, c) * (p - o);
    }
    
    
    float4 mainImage(float2 uv, float progress, float ratio, texture2d<float> inTexure1, texture2d<float> inTexure2, sampler sampler)
    {
        float2 uv0 = uv;
        uv -= 0.5;
        uv.x *= ratio;
        uv *= z;
        uv = rot(uv, float2(0.0), progress*speed);
        // uv.x = fract(uv.x/l/3.0)*l*3.0;
//        float theta = progress*6.+PI/.5;
        for(int iter = 0; iter < 10; iter++) {
            for(float i = 0.; i < 2. * PI; i+=deg) {
                float ts = sign(asin(cos(i))) == 1.0 ? 1.0 : 0.0;
                if(((ts == 1.0) && (uv.y-dist*cos(i) > tan(i)*(uv.x+dist*+sin(i)))) || ((ts == 0.0) && (uv.y-dist*cos(i) < tan(i)*(uv.x+dist*+sin(i))))) {
                    uv = refl(float2(uv.x+sin(i)*dist*2.,uv.y-cos(i)*dist*2.), float2(0.,0.), float2(cos(i),sin(i)));
                }
            }
        }
        uv += 0.5;
        uv = rot(uv, float2(0.5), progress*-speed);
        uv -= 0.5;
        uv.x /= ratio;
        uv += 0.5;
        uv = 2.*abs(uv/2.-floor(uv/2.+0.5));
        float2 uvMix = mix(uv,uv0,cos(progress*PI*2.)/2.+0.5);
        float4 color = mix(getFromColor(uvMix, inTexure1, sampler),getToColor(uvMix, inTexure2, sampler),cos((progress-1.)*PI)/2.+0.5);
        return color;
        
    }
    
    kernel void gl_01
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
         
         float4 out = mainImage(uv, progress, ratio, inTexture1, inTexture2, sampler);
         outTexture.write(out, grid);
     }
}


namespace TransitionGL02 {
    
    
    
    kernel void gl_02
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
         
         float count = 10.0;
         float smoothness = 0.5;
         
         float pr = smoothstep(-smoothness, 0.0, uv.x - progress * (1.0 + smoothness));
         float s = step(pr, fract(count * uv.x));
         
         float4 out1 = inTexture1.sample(sampler, uv);
         float4 out2 = inTexture2.sample(sampler, uv);
         
         float4 out =  mix(out1, out2, s);
         outTexture.write(out, grid);
     }
}
