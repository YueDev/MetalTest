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


namespace TransitionVideo {
    
    /// Screen 滤色 1   C=255-(A反相×B反相)/255
    float4 getscreencolor(float4 base, float4 overlay) {
        float4 one = float4(1.0);
        float4 rtn = one - (one - base) * (one - overlay);
        return rtn;
    }
    
    float4 getFromColor(float2 uv, texture2d<float> inTexture1, sampler sampler){
        return inTexture1.sample(sampler, uv);
    }
    
    float4 getToColor(float2 uv, texture2d<float> inTexture2, sampler sampler){
        return inTexture2.sample(sampler, uv);
    }
    
    
    
    // tran_test/split/split_tran.glsl
    // 视频分为左右两边，两个纹理先与右边的视频mix，得到的结果再与左边的视频screen
    kernel void transition_video_split
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     texture2d<float, access::sample> inTexture3 [[texture(3)]],
     sampler sampler [[ sampler(0) ]],
     constant TransitionPara &tranPara [[buffer(0)]],
     constant float& ratio [[ buffer(1) ]],
     uint2 grid [[thread_position_in_grid]]
     ) {
         float progress = tranPara.percent;
         float2 textureCoordinate = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 color1 = getFromColor(textureCoordinate, inTexture1, sampler);
         float4 color2 = getToColor(textureCoordinate, inTexture2, sampler);
         
         float2 pos = textureCoordinate;
         
         float ratio2= float(inTexture3.get_width()) / 2.0 / float(inTexture3.get_height());
         
         if(ratio>ratio2){
             pos.y=0.5+(pos.y-0.5)/ratio*ratio2;
         }else{
             pos.x=0.5+(pos.x-0.5)*ratio/ratio2;
         }
         pos.x /= 2.0;
         
         float4 colorscreen = inTexture3.sample(sampler, pos);
         
         pos.x += 0.5;
         
         float4 colormix = inTexture3.sample(sampler, pos);
         
         float4 coloruse = mix(color1, color2, colormix);
         coloruse = getscreencolor(coloruse, colorscreen);
         
         outTexture.write(coloruse, grid);
     }
    
    
    //mix 遮照类的视频
    kernel void transition_video_mix
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     texture2d<float, access::sample> inTexture3 [[texture(3)]],
     sampler sampler [[ sampler(0) ]],
     constant TransitionPara &tranPara [[buffer(0)]],
     constant float& ratio [[ buffer(1) ]],
     uint2 grid [[thread_position_in_grid]]
     ) {
         float progress = tranPara.percent;
         float2 textureCoordinate = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 color1 = getFromColor(textureCoordinate, inTexture1, sampler);
         float4 color2 = getToColor(textureCoordinate, inTexture2, sampler);
         
         float2 pos = textureCoordinate;
         
         float ratio2= float(inTexture3.get_width()) / float(inTexture3.get_height());
         
         if(ratio>ratio2){
             pos.y=0.5+(pos.y-0.5)/ratio*ratio2;
         }else{
             pos.x=0.5+(pos.x-0.5)*ratio/ratio2;
         }
                  
         
         float4 colormix = inTexture3.sample(sampler, pos);
         
         float4 out = mix(color1, color2, colormix);
         
         outTexture.write(out, grid);
     }
    
    
    //screen 光效类的
    kernel void transition_video_screen
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     texture2d<float, access::sample> inTexture3 [[texture(3)]],
     sampler sampler [[ sampler(0) ]],
     constant TransitionPara &tranPara [[buffer(0)]],
     constant float& ratio [[ buffer(1) ]],
     uint2 grid [[thread_position_in_grid]]
     ) {
         float progress = tranPara.percent;
         float2 textureCoordinate = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float4 color = progress > 0.5 ?  getToColor(textureCoordinate, inTexture2, sampler) : getFromColor(textureCoordinate, inTexture1, sampler);
         
         
         float2 pos = textureCoordinate;
         
         float ratio2= float(inTexture3.get_width()) / float(inTexture3.get_height());
         
         if(ratio>ratio2){
             pos.y=0.5+(pos.y-0.5)/ratio*ratio2;
         }else{
             pos.x=0.5+(pos.x-0.5)*ratio/ratio2;
         }
         
         float4 screencolor = inTexture3.sample(sampler, pos);
         
         float4 out = getscreencolor(color, screencolor);
         
         outTexture.write(out, grid);
     }
    
}
