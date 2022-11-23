//
//  TransitionSplit.metal
//  MetalTest
//
//  Created by YUE on 2022/11/22.
//

#include <metal_stdlib>
#include "Model.metal"

using namespace metal;
using namespace Model;

namespace TransitionSplit01 {
    
    float Sinusoidal_easeInOut(float begin, float change, float duration, float time) {
        return -change / 2.0 * (cos(PI * time / duration) - 1.0) + begin;
    }
    
    float rand (float2 co) {
        return fract(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
    }
    
    //获取相对的 once 的进度
    float getusepro(float2 originUV, float type, float splitnum, float once, float progress){
        
        float splitpos=0.0;
        //    type移动方向由另一个位置决定
        if (type==0.0){
            splitpos=originUV.y*splitnum;
        } else {
            splitpos=originUV.x*splitnum;
        }
        //    计算出这是第几部分
        splitpos=floor(splitpos);
        
        //    计算splitpos位置的延迟的启动时间progress
        float delaypos=(1.0-once)*splitpos/(splitnum-1.0);//(1.0-once)
        
        return (progress-delaypos)/once;
    }
    
    float getspeedpro(float usepro){
        return ((cos((usepro + 1.) * PI) / 2.0) + 0.5);
    }
    
    //转换pro 0-0.4不变 0.4-0.5映射成 0.4-0.9  0.5-1.0 映射成 0.9-1.0
    float getresetpro(float pro){
        pro=getspeedpro(pro);
        //原逻辑
        if (pro<0.4)pro=pro;
        else if (pro<=0.45){
            pro=0.4+(pro-0.4)*5.0;
        }else if(pro>=0.45&&pro<0.7){
            pro=0.65+(pro-0.45)*1.0;
        }else{
            pro=0.9+(pro-0.7)/3.0;
        }
        
        pro=getspeedpro(pro);
        pro=min(1.0,pro);
        return pro;
    }
    
    float2 resetpos(float2 uv, float type, float progress){
        //    超出镜像
        
        bool isx=type==0.0;
        if (progress<=0.5){
            if(isx){
                if (uv.x<0.0){
                    uv.x=-uv.x;
                }
            }else{
                if (uv.y>1.0){
                    uv.y=2.0-uv.y;
                }
            }
            
            
        }
        if (progress>0.5){
            if(isx){
                if (uv.x>0.0){
                    uv.x=1.0-uv.x;
                } else if (uv.x<0.0){
                    uv.x=1.0+uv.x;
                }
            }else{
                if (uv.y>0.0&&uv.y<1.0){
                    uv.y=1.0-uv.y;
                } else if (uv.y>1.0){
                    uv.y=uv.y-1.0;
                }
            }
        }
        
        return uv;
    }
    
    //01-08共用这个
    void splite
    (
     texture2d<float, access::sample> inTexture1,
     texture2d<float, access::sample> inTexture2,
     texture2d<float, access::write> outTexture,
     sampler sampler,
     uint2 grid,
     float progress,
     float ratio,
     bool isNew,
     float type,
     float splitnum
     ) {
         //isNew 是否是新的逻辑，分割2个的走新逻辑
         //type 0 横向 1 纵向  （34是 xy都移动，3是左上+xy右下-xy， 4是左下+xy右上-xy）
         //splitnum 分成几个部分
         //单程的时间
         float once=0.9;
         
         float strength2 = 0.6;
         
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         float2 originUV = uv;
         
         float usepro=getusepro(originUV, type, splitnum, once, progress);
         
         if (usepro <= 0.0){
             outTexture.write(inTexture1.sample(sampler, uv), grid);
             return;
         } else if (usepro >= 1.0){
             outTexture.write(inTexture2.sample(sampler, uv), grid);
             return;
         }
         
         float2 move = float2(0.0);
         float domove = getresetpro(usepro);
         
         if (type == 0.0){
             move.x = domove;
             uv = uv - move;
         } else {
             move.y = domove;
             uv = uv + move;
         }
         
         uv = resetpos(uv, type, progress);
         
         if (type == 0.0){
             move.x = domove / 8.0;
         } else {
             move.y = domove / 8.0;
         }
         
         domove = usepro * 1.0;
         if (usepro > 0.58){
             domove = max(0.65 - usepro, 0.0) * 4.0;
         }
         
         float strength = 0.0;
         if (isNew) {
             //新逻辑，2个的分割用
             strength = strength2 * progress / 0.5;
             if (progress > 0.5) {
                 float p = 1.0 - progress;
                 strength = max((p - 0.4), 0.0) / 0.1 * strength2 * 0.3;
             }
         } else {
             //原逻辑
             strength = strength2 * domove;
         }
         
         float3 color = float3(0.0);
         float total = 0.0;
         float2 toCenter = move;
         
         float offset = rand(uv);
         float dissolve = progress > 0.5 ? 1.0 : 0.0;
         if (strength==0.0){
             outTexture.write(inTexture2.sample(sampler, uv), grid);
             return;
         }
         
         float num = 10.0;
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
    
    kernel void split_01
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         splite(
                inTexture1,
                inTexture2,
                outTexture,
                sampler,
                grid,
                progress,
                ratio,
                true,
                0.0,
                2.0
                );
     }
}

namespace TransitionSplit02 {
    
    kernel void split_02
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         TransitionSplit01::splite(
                                   inTexture1,
                                   inTexture2,
                                   outTexture,
                                   sampler,
                                   grid,
                                   progress,
                                   ratio,
                                   true,
                                   1.0,
                                   2.0
                                   );
     }
    
}


namespace TransitionSplit03 {
    
    kernel void split_03
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         TransitionSplit01::splite(
                                   inTexture1,
                                   inTexture2,
                                   outTexture,
                                   sampler,
                                   grid,
                                   progress,
                                   ratio,
                                   false,
                                   0.0,
                                   3.0
                                   );
     }
    
}

namespace TransitionSplit04 {
    
    kernel void split_04
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         TransitionSplit01::splite(
                                   inTexture1,
                                   inTexture2,
                                   outTexture,
                                   sampler,
                                   grid,
                                   progress,
                                   ratio,
                                   false,
                                   1.0,
                                   3.0
                                   );
     }
    
}

namespace TransitionSplit05 {
    
    kernel void split_05
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         TransitionSplit01::splite(
                                   inTexture1,
                                   inTexture2,
                                   outTexture,
                                   sampler,
                                   grid,
                                   progress,
                                   ratio,
                                   false,
                                   0.0,
                                   4.0
                                   );
     }
    
}

namespace TransitionSplit06 {
    
    kernel void split_06
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         TransitionSplit01::splite(
                                   inTexture1,
                                   inTexture2,
                                   outTexture,
                                   sampler,
                                   grid,
                                   progress,
                                   ratio,
                                   false,
                                   1.0,
                                   4.0
                                   );
     }
    
}


namespace TransitionSplit07 {
    
    kernel void split_07
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         TransitionSplit01::splite(
                                   inTexture1,
                                   inTexture2,
                                   outTexture,
                                   sampler,
                                   grid,
                                   progress,
                                   ratio,
                                   false,
                                   0.0,
                                   8.0
                                   );
     }
    
}

namespace TransitionSplit08 {
    
    kernel void split_08
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         TransitionSplit01::splite(
                                   inTexture1,
                                   inTexture2,
                                   outTexture,
                                   sampler,
                                   grid,
                                   progress,
                                   ratio,
                                   false,
                                   1.0,
                                   8.0
                                   );
     }
    
}


namespace TransitionSplit09 {
    
    //09-10共用
    void splite
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]],
     float type
     ) {
         
         float strength2 = 0.5;
         
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         float domove = TransitionSplit01::getresetpro(progress);
         domove=progress >= 0.5 ? 1.0 - domove : domove;
         
         float2 move;
         float2 end;
         
         if(type == 1.0){
             move = float2(-domove, domove);
             if (uv.x + uv.y > 1.0){
                 if (progress < 0.5){
                     end = float2(1.0, 0.0);
                 } else{
                     end = float2(0.0, 1.0);
                 }
                 
             }
             else {
                 if (progress < 0.5){
                     end = float2(0.0,1.0);
                 } else{
                     end = float2(1.0, 0.0);
                 }
             }
         }else{
             move = float2(domove, domove);
             if (uv.x > uv.y){
                 if (progress < 0.5){
                     end = float2(0.0, 0.0);
                 } else{
                     end = float2(1.0, 1.0);
                 }
             }
             else  {
                 if (progress < 0.5){
                     end = float2(1.0, 1.0);
                 }else{
                     end = float2(0.0, 0.0);
                 }
             }
         }
         
         float2 needscale = uv - end;
         needscale *= (1.0 - domove);
         uv = end + needscale;
         
         float strength = TransitionSplit01::Sinusoidal_easeInOut(0.0, strength2, 0.5, progress);
         
         float3 color = float3(0.0);
         float total = 0.0;
         float2 toCenter = move / 4.0;
         
         float offset = TransitionSplit01::rand(uv);
         float dissolve = progress >= 0.5 ? 1.0 : 0.0;
         
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
    
    
    kernel void split_09
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         splite(
                inTexture1,
                inTexture2,
                outTexture,
                sampler,
                grid,
                progress,
                ratio,
                0.0
                );
     }
}

namespace TransitionSplit10 {
    
    kernel void split_10
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         TransitionSplit09::splite(
                                   inTexture1,
                                   inTexture2,
                                   outTexture,
                                   sampler,
                                   grid,
                                   progress,
                                   ratio,
                                   1.0
                                   );
     }
}

namespace TransitionSplit11 {
    
    
    float2 zhuanhua(float2 texCoord, float progress){
        //        0-1
        if (progress<0.5){
            //            x -y
            if ((texCoord.y<0.0)&&abs(texCoord.x-0.5)<=0.5){
                texCoord.y=-texCoord.y;
            } else // -x -y
                if (texCoord.x<0.0&&texCoord.y<0.0){
                    texCoord.x=-texCoord.x;
                    texCoord.y=-texCoord.y;
                }
        } else {
            //            +x y
            if (abs(texCoord.y-0.5)<=0.5&&texCoord.x>1.0){
                texCoord.x=2.0-texCoord.x;
            } else//+x+y
                if (texCoord.x>1.0&&texCoord.y>1.0){
                    texCoord.x=2.0-texCoord.x;
                    texCoord.y=2.0-texCoord.y;
                }
        }
        return texCoord;
    }
    
    float2 zhuanhua2(float2 texCoord, float progress){
        if (progress<0.5){
            //x +y
            if (texCoord.y>1.0&&abs(texCoord.x-0.5)<=0.5){
                texCoord.y=2.0-texCoord.y;
            } else //+x +y
                if (texCoord.x>1.0&&texCoord.y>1.0){
                    texCoord.x=2.0-texCoord.x;
                    texCoord.y=2.0-texCoord.y;
                }
        }else{
            //-x y
            if (abs(texCoord.y-0.5)<=0.5&&texCoord.x<0.0){
                texCoord.x=-texCoord.x ;
            } else//-x -y
                if (texCoord.x<0.0&&texCoord.y<0.0){
                    texCoord.x=-texCoord.x;
                    texCoord.y=-texCoord.y;
                }
        }
        return texCoord;
    }
    
    float2 resettexCoord(float2 texCoord,float2 move, float progress){
        if (texCoord.x>texCoord.y){
            move=-move;
            texCoord=texCoord+move;
            texCoord=zhuanhua(texCoord, progress);
        } else {
            texCoord=texCoord+move;
            texCoord=zhuanhua2(texCoord, progress);
        }
        return texCoord;
    }
    
    
    
    kernel void split_11
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float type=1.0;
         float strength2 = 0.5;
         
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         float domove = TransitionSplit01::getresetpro(progress);
         domove = progress >= 0.5 ? 1.0 - domove : domove;
         float2 move = float2(domove, domove);
         if (progress>=0.5) move = -move;
         if(type == 1.0){
             if(uv.x > uv.y + 0.5 || uv.x < uv.y - 0.5){
                 move /= 2.0;
             }
         }
         
         float num=10.0;
         float total=0.0;
         float offset = TransitionSplit01::rand(uv);
         float dissolve = progress >= 0.5 ? 1.0 : 0.0;
         float3 color = float3(0.0);
         
         for (float t = 0.0; t <= num; t++) {
             float percent = (t + offset) / num;
             float weight = 4.0 * (percent - percent * percent);
             float2 newUV = resettexCoord(uv ,move * (1.0 + 0.2 * percent * strength2), progress);
             float3 color1 = inTexture1.sample(sampler, newUV).rgb;
             float3 color2 = inTexture2.sample(sampler, newUV).rgb;
             color += mix(color1, color2, dissolve) * weight;
             total += weight;
         }
         
         float4 out = float4(color / total, 1.0);
         outTexture.write(out, grid);
         
     }
}

namespace TransitionSplit12 {
    
    
    float2 zhuanhua(float2 texCoord, float progress){
        
        if (abs(texCoord.x-0.5)>0.5||abs(texCoord.y-0.5)>0.5){
            if (progress<0.5){
                //            -x y
                if ((texCoord.x<0.0)&&abs(texCoord.y-0.5)<=0.5){
                    texCoord.x=-texCoord.x;
                } else // -x +y
                    if (texCoord.x<0.0&&texCoord.y>1.0){
                        texCoord.x=-texCoord.x;
                        texCoord.y=2.0-texCoord.y;
                    }
            } else {
                //            x -y
                if (abs(texCoord.x-0.5)<=0.5&&texCoord.y<0.0){
                    texCoord.y=-texCoord.y;
                } else//+x-y
                    if (texCoord.x>1.0&&texCoord.y<0.0){
                        texCoord.x=2.0-texCoord.x;
                        texCoord.y=-texCoord.y;
                    }
                
            }
            
            
        }
        return texCoord;
        
    }
    
    float2 zhuanhua2(float2 texCoord, float progress){
        
        if (progress<0.5){
            //+x y
            if (texCoord.x>1.0&&abs(texCoord.y-0.5)<=0.5){
                texCoord.x=2.0-texCoord.x;
            } else //+x -y
                if (texCoord.x>1.0&&texCoord.y<0.0){
                    texCoord.x=2.0-texCoord.x;
                    texCoord.y=-texCoord.y;
                }
        }else{
            //x +y
            if (abs(texCoord.x-0.5)<=0.5&&texCoord.y>=1.0){
                texCoord.y=2.0-texCoord.y;
            } else//-x +y
                if (texCoord.x<0.0&&texCoord.y>1.0){
                    texCoord.x=-texCoord.x;
                    texCoord.y=2.0-texCoord.y;
                }
        }
        return texCoord;
    }
    
    
    
    float2 resettexCoord(float2 texCoord,float2 move, float progress){
        
        if (texCoord.x+texCoord.y>1.0){
            move=-move;
            texCoord=texCoord+move;
            texCoord=zhuanhua2(texCoord, progress);
        } else {
            texCoord=texCoord+move;
            texCoord=zhuanhua(texCoord, progress);
        }
        return texCoord;
        
    }
    
    
    
    kernel void split_12
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ){
         float type=1.0;
         float strength2 = 0.5;
         
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         float domove = TransitionSplit01::getresetpro(progress);
         domove = progress >= 0.5 ? 1.0 - domove : domove;
         float2 move = float2(-domove, domove);
         if (progress>=0.5) move = -move;
         if(type == 1.0){
             if(uv.x+uv.y>1.5||uv.x+uv.y<0.5){
                 move /= 2.0;
             }
         }
         
         float num=10.0;
         float total=0.0;
         float offset = TransitionSplit01::rand(uv);
         float dissolve = progress >= 0.5 ? 1.0 : 0.0;
         float3 color = float3(0.0);
         
         for (float t = 0.0; t <= num; t++) {
             float percent = (t + offset) / num;
             float weight = 4.0 * (percent - percent * percent);
             float2 newUV = resettexCoord(uv ,move * (1.0 + 0.2 * percent * strength2), progress);
             float3 color1 = inTexture1.sample(sampler, newUV).rgb;
             float3 color2 = inTexture2.sample(sampler, newUV).rgb;
             color += mix(color1, color2, dissolve) * weight;
             total += weight;
         }
         
         float4 out = float4(color / total, 1.0);
         outTexture.write(out, grid);
     }
}

namespace TransitionSplit13 {
    
    
    bool isin(float2 c2, float ratio, float centerx, float centery, float radius){
        
        //    先判断在不在矩形范围内
        //    中心点 距离xy轴的距离
        float rx=radius;
        float ry=radius;
        float2 center=float2(centerx, centery);
        //    距离中心点的相对坐标xy
        float2 cha=c2-center;
        //    宽>高
        if (ratio>1.0){
            rx=radius/ratio;
        } else {
            ry=radius*ratio;
        }
        if (abs(cha.x)>rx||abs(cha.y)>ry){
            return false;
        } else {
            bool isin=(cha.x*cha.x)/(rx*rx)+(cha.y*cha.y)/(ry*ry)<=1.0;
            return isin;
        }
    }
    
    float2 doroate(float2 c2, float roate, float scale, float ratio, float centerx, float centery){
        
        
        float2 center=float2(centerx, centery);
        
        //计算旋转角度
        float2 uv2  =c2-center;
        if (ratio>1.0){
            uv2.x=uv2.x*ratio;
        } else {
            uv2.y=uv2.y/ratio;
        }
        float c = cos(roate);
        float s = sin(roate);
        float dx2 = uv2.x*c+uv2.y*s;
        float dy2 = -uv2.x*s+uv2.y*c;
        if (ratio>1.0){
            dx2=dx2/ratio;
        } else {
            dy2=dy2*ratio;
        }
        float2 rtn=float2(center.x+dx2/scale, center.y+dy2/scale);
        return rtn;
    }
    
    kernel void split_13
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ) {
         
         float centerx=0.5;
         //float centery=1.0;
         float centery=0.5;
         //椭圆中心点的长径
         float radius=0.6;
         
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         bool isin1 = isin(uv, ratio, centerx, centery, radius);
         
         float usepro = progress;
         
         if (!isin1){
             if (progress >= 0.5){
                 usepro = (1.0 - progress) * 2.0;
                 usepro = 1.0 - usepro * usepro / 2.0;
             } else {
                 usepro = progress * 2.0;
                 usepro = usepro * usepro / 2.0;
             }
         }
         
         usepro = TransitionSplit01::getresetpro(usepro);
         //    180度＝π弧度
         float roate = usepro * PI * 2.0;
         float2 offuse = doroate(uv, roate, 1.0, ratio, centerx, centery);
         if (offuse.x < 0.)offuse.x = -offuse.x;
         if (offuse.y < 0.)offuse.y = -offuse.y;
         if (offuse.x > 1.)offuse.x = 2.0-offuse.x;
         if (offuse.y>  1.)offuse.y = 2.0-offuse.y;
         
         float3 color = float3(0.0);
         float total = 0.0;
         float offset = TransitionSplit01::rand(offuse);
         float num = 10.0;
         usepro = progress > 0.5 ? 1.0 - progress : progress;
         
         for (float t = 0.0; t <= num; t++) {
             float percent = (t + offset) / num;
             float weight = 4.0 * (percent - percent * percent);
             float needroate = roate - (num - t) * 0.05 * usepro;
             if (!isin1 && progress < 0.15 && needroate <0.0){
                 if(total == 0.0){
                     float4 out = progress< 0.5 ? inTexture1.sample(sampler, uv) : inTexture2.sample(sampler, uv);
                     outTexture.write(out, grid);
                 }else{
                     float4 out = float4(color / total, 1.0);
                     outTexture.write(out, grid);
                 }
                 return;
             }
             
             float2 movepos = doroate(uv, needroate, 1.0, ratio, centerx, centery);
             if (movepos.x < 0.0) movepos.x = -movepos.x;
             if (movepos.y < 0.0) movepos.y = -movepos.y;
             if (movepos.x > 1.0) movepos.x = 2.0-movepos.x;
             if (movepos.y > 1.0) movepos.y = 2.0-movepos.y;
             color += (
                       progress< 0.5 ?
                       inTexture1.sample(sampler, movepos).rgb :
                       inTexture2.sample(sampler, movepos).rgb
                       ) * weight;
             total += weight;
         }
         
         float4 out = float4(color / total, 1.0);
         outTexture.write(out, grid);
     }
}

namespace TransitionSplit14 {
    
    float2 doroate(float2 c2, float roate, float direction, float scale, float ratio, float centerx, float centery){
        return TransitionSplit13::doroate(c2, roate * direction, scale, ratio, centerx, centery);
    }
    
    kernel void split_14
    (
     texture2d<float, access::sample> inTexture1 [[texture(0)]],
     texture2d<float, access::sample> inTexture2 [[texture(1)]],
     texture2d<float, access::write> outTexture [[texture(2)]],
     sampler sampler [[ sampler(0) ]],
     uint2 grid [[thread_position_in_grid]],
     constant float& progress [[ buffer(0) ]],
     constant float& ratio [[ buffer(1) ]]
     ) {
         
         float centerx=0.5;
         float centery=1.0;
         //椭圆中心点的长径
         float radius=0.6;
         //1.0 顺时针 -1逆
         float direction=1.0;
         float yanchi=0.05;
         float type = 0.0;
         
         float2 uv = float2(grid) / float2(outTexture.get_width(), outTexture.get_height());
         
         if (!TransitionSplit13::isin(uv, ratio, centerx, centery, radius)){
             type = 1.0;
             if (centery != 0.5){
                 radius = 1.1;
                 if (!TransitionSplit13::isin(uv, ratio, centerx, centery, radius))
                     type = 2.0;
             }
         }
         
         //    超出范围直接返回
         if (type == 0.0 && progress >= 1.0 - yanchi * 2.0){
             float4 out = progress< 0.5 ? inTexture1.sample(sampler, uv) : inTexture2.sample(sampler, uv);
             outTexture.write(out, grid);
             return;
         }
         if (type == 1.0 && (progress <= yanchi || progress >= 1.0 - yanchi)){
             float4 out = progress< 0.5 ? inTexture1.sample(sampler, uv) : inTexture2.sample(sampler, uv);
             outTexture.write(out, grid);
             return;
         }
         if (type == 2.0 && (progress <= yanchi * 2.0)){
             float4 out = progress< 0.5 ? inTexture1.sample(sampler, uv) : inTexture2.sample(sampler, uv);
             outTexture.write(out, grid);
             return;
         }

         float newprogress = 0.0;
         if (type == 0.0){
             newprogress = progress/(1.0 - yanchi * 2.0);
         } else if (type == 1.0){
             newprogress = (progress - yanchi) / (1.0 - yanchi * 2.0);
         }else {
             newprogress = (progress - yanchi * 2.0) / (1.0 - yanchi * 2.0);
         }
         newprogress = TransitionSplit01::getresetpro(newprogress);
         
         float roate = newprogress * PI * 2.0;
         float2 offuse = doroate(uv, roate, direction, 1.0, ratio, centerx, centery);
         if (offuse.x < 0.0&& offuse.x > -1.0) offuse.x = -offuse.x;
         if (offuse.y < 0.0&& offuse.y > -1.0) offuse.y = -offuse.y;
         if (offuse.x < -1.0) offuse.x = 2.0 + offuse.x;
         if (offuse.y < -1.0) offuse.y = 2.0 + offuse.y;
         if (offuse.x > 1.0) offuse.x = 2.0 - offuse.x;
         if (offuse.y > 1.0) offuse.y = 2.0 - offuse.y;
         
         float3 color = float3(0.0);
         float total = 0.0;
         float offset = TransitionSplit01::rand(offuse);
         float num = 10.0;
         newprogress = newprogress > 0.5 ? 1.0 - newprogress : newprogress;
         
         for (float t = 0.0; t <= num; t++) {
             float percent = (t + offset) / num;
             float weight = 4.0 * (percent - percent * percent);
             float needroate = roate - (num - t) * 0.05 * newprogress;
             float2 movepos = doroate(uv, needroate, direction, 1.0, ratio, centerx, centery);

             if (movepos.x > 1.0) movepos.x= 2.0 - movepos.x;
             if (movepos.x < 0.0 && movepos.x> -1.0) movepos.x = -movepos.x;
             if (movepos.x < -1.0) movepos.x= 2.0 + movepos.x;
 
             if (movepos.y > 1.0) movepos.y = 2.0 - movepos.y;
             if (movepos.y < 0.0 && movepos.x >- 1.0) movepos.y = -movepos.y;
             if (movepos.y < -1.0) movepos.y = 2.0 + movepos.y;

             color += (
                       progress< 0.5 ?
                       inTexture1.sample(sampler, movepos).rgb :
                       inTexture2.sample(sampler, movepos).rgb
                       ) * weight;
             total += weight;
         }
         float4 out = float4(color / total, 1.0);
         outTexture.write(out, grid);
     }
    
}

