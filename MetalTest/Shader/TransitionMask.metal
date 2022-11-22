//
//  MetalTest
//
//  Created by YUE on 2022/11/21.
//

#include <metal_stdlib>
#include "Model.metal"
using namespace metal;
using namespace Model;

namespace TransitionMark01 {
    
    float2 resetuse(float2 offuse){
        if (offuse.x<0.0&&offuse.x>-1.0)offuse.x=-offuse.x;
        if (offuse.y<0.0&&offuse.y>-1.0)offuse.y=-offuse.y;
        if (offuse.x>1.0)offuse.x=2.0-offuse.x;
        if (offuse.y>1.0)offuse.y=2.0-offuse.y;
        return offuse;
    }
    
    float check(float2 p1, float2 p2, float2 p3){
        return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
    }
    
    //是否在三角形内
    bool isin_triangle(float2 pt, float2 p1, float2 p2, float2 p3){
        bool b1, b2, b3;
        b1 = check(pt, p1, p2) < 0.0;
        b2 = check(pt, p2, p3) < 0.0;
        b3 = check(pt, p3, p1) < 0.0;
        return ((b1 == b2) && (b2 == b3));
    }
    
    // roate PI=180
    //在0，0处旋转，不需要设置center
    float2 doroate(float2 c2, float roate, float ratio){
        //计算旋转角度
        float2 uv2  =c2;
        if (ratio<1.0){
            uv2.x=uv2.x*ratio;
        } else {
            uv2.y=uv2.y/ratio;
        }
        float c = cos(roate);
        float s = sin(roate);
        float dx2 = uv2.x*c+uv2.y*s;
        float dy2 = -uv2.x*s+uv2.y*c;
        if (ratio<1.0){
            dx2=dx2/ratio;
        } else {
            dy2=dy2*ratio;
        }
        float2 rtn = float2(dx2, dy2);
        return rtn;
    }
    
    
    float getspeedpro(float usepro){
        return ((cos((usepro + 1.) * PI) / 2.0) + 0.5);
    }
    
    //转换pro 0-0.4不变 0.4-0.5映射成 0.4-0.9  0.5-1.0 映射成 0.9-1.0
    float getresetpro(float pro){
        pro = getspeedpro(pro);
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
    
    
    kernel void mark_01
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
         if (progress<0.02){
             outTexture.write(inTexture1.sample(sampler, uv), grid);
             return;
         }
         
         float useprogress = getresetpro(progress*0.4+0.2);
         float2 center = float2(0.5);
         float2 move = float2(0);
         center += move * useprogress;
         
         //func setpoints in opengl.
         float length = useprogress*1.6;
         float roate = PI*length;
         if(ratio>1.0){
             length = length * ratio;
         }
         
         float2 movecenter = float2(0.0, length);
         movecenter = doroate(movecenter,-roate, ratio);
         float2 moveleft = doroate(movecenter, PI*(0.66), ratio);
         float2 moveright = doroate(movecenter, -PI*(0.66), ratio);
         
         float isin = isin_triangle(uv, center + movecenter, center + moveleft, center + moveright) ? 1.0 : 0.0;
         
         float2 useto = center + (uv - center) * (1.0 - (useprogress - 1.0) * 0.2);
         useto = resetuse(useto);
         
         float4 out = mix(
                          inTexture1.sample(sampler, uv),
                          inTexture2.sample(sampler, useto),
                          isin
                          );
         
         outTexture.write(out, grid);
     }
}

namespace TransitionMark02 {
    
    float2 doroate(float2 c2, float roate, float2 center, float ratio){
        //计算旋转角度
        float2 uv2 =c2-center;
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
        float2 rtn=float2(center.x+dx2, center.y+dy2);
        return rtn;
    }
    
    float2 resetuse(float2 offuse){
        if (offuse.x<0.0&&offuse.x>-1.0)offuse.x=-offuse.x;
        if (offuse.y<0.0&&offuse.y>-1.0)offuse.y=-offuse.y;
        if (offuse.x>1.0)offuse.x=2.0-offuse.x;
        if (offuse.y>1.0)offuse.y=2.0-offuse.y;
        return offuse;
    }
    
    
    
    kernel void mark_02
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
         if(progress == 1.0f){
             outTexture.write(inTexture2.sample(sampler, uv), grid);
             return;
         }
         
         float start = 0.05;
         float2 center = float2(0.5);
         
         
         float useprogress;
         useprogress = ((cos((progress + 1.0) * PI) / 2.0) + 0.5);
         float xx = useprogress / 2.0 * 1.2 + start;
         float yy = useprogress / 2.0 * 1.2 + start;
         
         if(ratio > 1.0){
             yy *= ratio;
         }else{
             xx /= ratio;
         }
         
         float2 afterroate = doroate(uv, PI / 4.0, center, ratio);
         bool isinbool = false;
         isinbool = abs(afterroate.x - center.x) < xx && abs(afterroate.y - center.y) < yy;
         float isin = (isinbool) ? 1.0 : 0.0;
         if(progress < 0.1){
             isin *= (progress * 10.0);
         }
         
         float2 useto = center + (uv - center) * (1.0 - (useprogress - 1.0) * 0.2);
         useto = resetuse(useto);
         float4 out = mix(
                          inTexture1.sample(sampler, uv),
                          inTexture2.sample(sampler, useto),
                          isin
                          );
         outTexture.write(out, grid);
         
     }
}

namespace TransitionMark03 {
    
    //同一个位置的坐标拿两个随机数
    float2 getstartmove(float texCoord, float splitnum){
        float usenum=texCoord*100.0;
        //    转成整数
        int num1=int(usenum/splitnum);
        float num=float(num1)*splitnum/100.0;
        num+=1.0;
        float r1=fract(num*num*2.98*43.53);
        float r2=fract(r1*1.98*47.543);
        return float2(-(r1*r1)/6.0, -(r2*r2)/6.0);
    }
    float4 getstartmove2(float texCoord, float splitnum){
        float usenum=texCoord*100.0;
        //    转成整数
        int num1=int(usenum/splitnum);
        float num=float(num1)*splitnum/100.0;
        num+=1.0;
        float r1=fract(num*num*2.98*43.53);
        float r2=fract(r1*1.98*47.543);
        float r3=fract(r2*1.78*47.123);
        float r4=fract(r3*1.67*47.456);
        return float4(r1*r2, r2*r3, r3*r4, r4*r1);
    }
    
    
    float getuseprogress(float mi, float progress){
        float useprogress= progress >= 0.5 ? 1.0 - progress : progress;
        useprogress = pow(useprogress * 2.0, mi)/2.0;
        useprogress = progress >= 0.5 ? 1.0 - useprogress : useprogress;
        useprogress = (cos((useprogress + 1.0) * PI) / 2.0) + 0.5;
        return useprogress;
    }
    
    kernel void mark_03
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
         
         // y坐标每100/splitnum算作一个部分，y轴作为短边时候20个，若是长边则/ratio增加相应数量
         float splitnum=10.0;
         //横向中心纵向中心
         float hengshu=0.0;
         //=0 中心向两侧 1两侧向中心
         float isstartcenter=0.0;
         //0 指从中间开始分裂1的话从0.25 0.75处开始
         float centernum=0.0;
         
         
         //    用哪个值来进行计算startmove
         float choosenum = uv.x;
         //    用哪个值判断
         float boolnum = uv.y;
         if (hengshu == 0.0){
             choosenum = uv.y;
             boolnum = uv.x;
         }
         
         bool isinbool=  false;
         float usepro = getuseprogress(1.5, progress);
         if (isstartcenter == 0.0){
             if (centernum == 0.0){
                 float2 startmove = getstartmove(choosenum, splitnum);
                 if (boolnum <= 0.5){
                     isinbool = boolnum > (0.5 - (usepro * 0.65 + startmove.x));
                 } else {
                     isinbool = boolnum < (0.5 + (usepro * 0.65 + startmove.y));
                 }
             } else {
                 float4 startmove = getstartmove2(choosenum, splitnum);
                 if (boolnum <= 0.25){
                     isinbool=boolnum>(0.25-usepro*(usepro*0.25+startmove.r));
                 } else if (boolnum>=0.75){
                     isinbool=boolnum<(0.75+usepro*(usepro*0.25+startmove.g));
                 } else {
                     isinbool=
                     boolnum>(0.75-usepro*(usepro*0.25+startmove.b))
                     ||boolnum<(0.25+usepro*(usepro*0.25+startmove.a));
                 }
             }
             
         }
         else {
             float2 startmove=getstartmove(choosenum, splitnum);
             isinbool=boolnum>
             (1.0-usepro*(usepro*0.5+startmove.y))||boolnum<(usepro*(usepro*0.5+startmove.x));
         }
         float isin=(isinbool)?1.0:0.0;
         
         float2 center=float2(0.5);
         float2 usefrom=center+(uv-center)*(1.0-progress*0.2);
         float2 useto=center+(uv-center)*(1.0-(1.0-progress)*0.2);
         float4 out = mix(
                          inTexture1.sample(sampler, usefrom),
                          inTexture2.sample(sampler, useto),
                          isin
                          );
         
         outTexture.write(out, grid);
     }
}


namespace TransitionMark04 {
    
    float isin(float2 use, float a, float b, float usepro, float tpointx){
        
        if(use.y>a*use.x+b+(usepro*max(tpointx,1.0-tpointx)*1.1*a))
            return 0.0;
        if(use.y<a*use.x+b-(usepro*max(tpointx,1.0-tpointx)*1.1*a))
            return 0.0;
        
        return 1.0;
    }
    
    
    float getuseprogress(float mi, float progress){
        float useprogress= progress >= 0.5 ? 1.0 - progress : progress;
        useprogress = pow(useprogress * 2.0, mi)/2.0;
        useprogress = progress >= 0.5 ? 1.0 - useprogress : useprogress;
        useprogress = (cos((useprogress + 1.0) * PI) / 2.0) + 0.5;
        return useprogress;
    }
    
    float2 resetuse(float2 offuse){
        if (offuse.x<0.0&&offuse.x>-1.0)offuse.x=-offuse.x;
        if (offuse.y<0.0&&offuse.y>-1.0)offuse.y=-offuse.y;
        if (offuse.x>1.0)offuse.x=2.0-offuse.x;
        if (offuse.y>1.0)offuse.y=2.0-offuse.y;
        return offuse;
    }
    
    
    kernel void mark_04
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
         
         float2 center = float2(0.5);
         
         
         float tpointx = 0.6;
         float bpointx = 1.0 - tpointx;
         //方程式是 y=ax+b;
         float a = 1.0;
         float b = 1.0;
         
         float usepro = 0.0;
         
         a = 1.0 / (tpointx - bpointx);
         b = -(a * bpointx);
         usepro = getuseprogress(2.0, progress);
         float2 useto = center + (uv - center) * (1.0 - (progress - 1.0) * 0.2);
         useto=resetuse(useto);
         float4 out = mix(
                          inTexture1.sample(sampler, uv),
                          inTexture2.sample(sampler, useto),
                          isin(uv, a, b, usepro, tpointx)
                          );
         
         outTexture.write(out, grid);
     }
}

namespace TransitionMark05 {
    
    
    float2 getstartmove(float texCoord, float splitnum, float xishu, float jiaocha){
        float usenum=texCoord*100.0;
        //    转成0-19个整数
        int num1 = int(usenum/splitnum);
        float danshuang = fmod(float(num1),2.0f);
        
        float num=float(num1)*splitnum/100.0;
        if(jiaocha>0.2&&danshuang==1.0){
            num=1.0-num;
        }
        //    负的偏移量 0-0.4
        float my=-(1.0-num*num)*xishu;
        if(jiaocha==1.0)
            my=-((cos((num + 1.) * PI) / 2.0) + 0.5)*xishu;
        float2 startmove=float2(danshuang, my);
        return startmove;
    }
    
    
    float getuseprogress(float mi, float progress){
        float useprogress= progress >= 0.5 ? 1.0 - progress : progress;
        useprogress = pow(useprogress * 2.0, mi)/2.0;
        useprogress = progress >= 0.5 ? 1.0 - useprogress : useprogress;
        useprogress = (cos((useprogress + 1.0) * PI) / 2.0) + 0.5;
        return useprogress;
    }
    
    
    kernel void mark_05
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
         
         
         // y坐标每100/splitnum算作一个部分，y轴作为短边时候20个，若是长边则/ratio增加相应数量
         float splitnum = 4.0;
         //0.0顺序排列 1.0 交叉
         float hengshu = 0.0;
         float jiaocha = 0.0;
         float xishu = 0.4;
         
         //    用哪个值来进行计算startmove
         float choosenum = uv.x;
         //    用哪个值判断
         float boolnum = uv.y;
         if(hengshu == 1.0){
             choosenum = uv.y;
             boolnum = uv.x;
         }
         float2 startmove = getstartmove(choosenum, splitnum, xishu, jiaocha);
         bool isinbool = false;
         
         float useprogress = getuseprogress(2.0, progress);
         if (startmove.x == 0.0){
             isinbool = boolnum < (useprogress * 1.6 + startmove.y);
         } else {
             isinbool = boolnum > 1.0-(useprogress * 1.6 + startmove.y);
         }
         
         float isin = (isinbool) ? 1.0 : 0.0;
         float2 center = float2(0.5);
         float2 usefrom = center + (uv - center) * (1.0 - progress * 0.2);
         float2 useto = center + (uv - center) * (1.0 - (1.0 - progress) * 0.2);
         
         float4 out = mix(
                          inTexture1.sample(sampler, usefrom),
                          inTexture2.sample(sampler, useto),
                          isin
                          );
         
         outTexture.write(out, grid);
         
     }
}

namespace TransitionMark06 {
    
    
    
    float getuseprogress(float mi, float progress){
        float useprogress= progress >= 0.5 ? 1.0 - progress : progress;
        useprogress = pow(useprogress * 2.0, mi)/2.0;
        useprogress = progress >= 0.5 ? 1.0 - useprogress : useprogress;
        useprogress = (cos((useprogress + 1.0) * PI) / 2.0) + 0.5;
        return useprogress;
    }
    float2 resetuse(float2 offuse){
        if (offuse.x<0.0&&offuse.x>-1.0)offuse.x=-offuse.x;
        if (offuse.y<0.0&&offuse.y>-1.0)offuse.y=-offuse.y;
        if (offuse.x>1.0)offuse.x=2.0-offuse.x;
        if (offuse.y>1.0)offuse.y=2.0-offuse.y;
        return offuse;
    }
    
    
    
    kernel void mark_06
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
         
         if(progress == 0.0){
             float4 out = inTexture1.sample(sampler, uv);
             outTexture.write(out, grid);
             return;
         }
         if(progress == 1.0){
             float4 out = inTexture2.sample(sampler, uv);
             outTexture.write(out, grid);
             return;
         }
         
         const int num = 10;
         float4 array[num] = {
             float4(0.9, 0.2, 0.5,1.0),
             float4(0.4, 0.5, 0.7,1.0),
             float4(0.8, 0.7, 0.6,1.0),
             float4(0.1, 0.1, 0.5,1.0),
             float4(-0.1, 0., 0.3,0.5),
             float4(0.15, 0.8, 0.35,0.4),
             float4(0.7, 0.4, 0.15,0.6),
             float4(0.2, 0.45, 0.3,0.3),
             float4(0.5, 0.9, 0.4,0.5),
             float4(1.1, 0.8, 0.15,0.5),
         };
         
         float usepro = getuseprogress(1.5, progress);
         usepro = usepro * 0.6 + 0.02;
         float2 ratio2 = ratio < 1.0 ? float2(1, 1.0 / ratio) : float2(ratio, 1.0);
         
         
         
         //fun incile in tcileout.glsl
         float mixvalue = 0.0;
         for (int i = 0;i < num; i++){
             float4 bijiao=array[i];
             float s = bijiao.z * usepro;
             if(bijiao.z>=0.5){
                 s+=bijiao.z/6.0;
             }
             float dist = length((uv- bijiao.xy) * ratio2);
             if (dist<s){
                 mixvalue = usepro*7.0*(1.0+bijiao.a);
             }
         }
         
         mixvalue = min(usepro + mixvalue, 1.0);
         
         float2 center = float2(0.5);
         float2 useto = center + (uv - center) * (1.0 - (progress - 1.0) * 0.2);
         useto=resetuse(useto);
         float4 out = mix(
                          inTexture1.sample(sampler, uv),
                          inTexture2.sample(sampler, useto),
                          mixvalue
                          );
         outTexture.write(out, grid);
     }
}

namespace TransitionMark07 {
    
    
    float2 doroate(float2 c2, float2 center,float roate, float ratio){
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
        float2 rtn=float2(center.x+dx2, center.y+dy2);
        return rtn;
    }
    
    float getspeedpro(float usepro){
        return ((cos((usepro + 1.) * PI) / 2.0) + 0.5);
    }
    
    float getresetpro(float pro){
        pro=getspeedpro(pro);
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
    
    float2 resetuse(float2 offuse){
        if (offuse.x<0.0&&offuse.x>-1.0)offuse.x=-offuse.x;
        if (offuse.y<0.0&&offuse.y>-1.0)offuse.y=-offuse.y;
        if (offuse.x>1.0)offuse.x=2.0-offuse.x;
        if (offuse.y>1.0)offuse.y=2.0-offuse.y;
        return offuse;
    }
    
    
    
    kernel void mark_07
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
         if(progress<0.02){
             outTexture.write(inTexture1.sample(sampler, uv), grid);
             return;
         }
         if(progress>0.98){
             outTexture.write(inTexture2.sample(sampler, uv), grid);
             return;
         }
         
         //初始中心点
         float2 rectcenter = float2(0.5,1.2);
         //中心点移动方向速度 移动完后rectcenter=rectcenter+rectmove；
         float2 rectmove = float2(0.0,-0.6);
         //初始半径的一半
         float startradios = 0.15;
         
         float useprogress = getresetpro(progress * 0.4 + 0.2);
         rectcenter = rectcenter + rectmove * useprogress;
         float2 afterroate = doroate(uv, rectcenter, PI * (useprogress + 0.2), ratio);
         float xx = startradios +useprogress;
         float yy = startradios + useprogress;
         float xaad = 0.03 * (1.0 - useprogress);
         float yaad = 0.03 * (1.0 - useprogress);
         
         if(ratio>1.0){
             yy*=ratio;
             yaad*=ratio;
         }else{
             xx/=ratio;
             xaad/=ratio;
         }
         
         bool isinbool=false;
         isinbool = abs(afterroate.x - rectcenter.x) < xx && abs(afterroate.y - rectcenter.y) < yy;
         float isin = isinbool ? 1.0 : 0.0;
         
         float2 center = float2(0.5);
         float2 useto = center + (uv - center) * (1.0 - (useprogress - 1.0) * 0.2);
         useto = resetuse(useto);
         float4 out= mix(
                         inTexture1.sample(sampler, uv),
                         inTexture2.sample(sampler, useto),
                         isin
                         );
         outTexture.write(out, grid);
     }
}

namespace TransitionMark08 {
    
    float2 doroate(float2 c2, float roate, float ratio){
        //计算旋转角度
        float2 uv2  = c2;
        if (ratio < 1.0){
            uv2.x = uv2.x * ratio;
        } else {
            uv2.y = uv2.y / ratio;
        }
        float c = cos(roate);
        float s = sin(roate);
        float dx2 = uv2.x * c+uv2.y*s;
        float dy2 = -uv2.x* s+uv2.y*c;
        if (ratio < 1.0){
            dx2 = dx2 / ratio;
        } else {
            dy2 = dy2 * ratio;
        }
        float2 rtn = float2(dx2, dy2);
        return rtn;
    }
    
    float check(float2 p1, float2 p2, float2 p3){
        return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
    }
    
    bool isin_triangle(float2 pt, float2 p1, float2 p2, float2 p3){
        bool b1, b2, b3;
        b1 = check(pt, p1, p2) < 0.0;
        b2 = check(pt, p2, p3) < 0.0;
        b3 = check(pt, p3, p1) < 0.0;
        return ((b1 == b2) && (b2 == b3));
    }
    
    float getspeedpro(float usepro){
        return ((cos((usepro + 1.) * PI) / 2.0) + 0.5);
    }
    
    float2 resetuse(float2 offuse){
        if (offuse.x<0.0&&offuse.x>-1.0)offuse.x=-offuse.x;
        if (offuse.y<0.0&&offuse.y>-1.0)offuse.y=-offuse.y;
        if (offuse.x>1.0)offuse.x=2.0-offuse.x;
        if (offuse.y>1.0)offuse.y=2.0-offuse.y;
        return offuse;
    }
    
    float getresetpro(float pro){
        pro=getspeedpro(pro);
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
    
    
    kernel void mark_08
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
         if(progress<0.02){
             outTexture.write(inTexture1.sample(sampler, uv), grid);
             return;
         }
         if(progress>0.98){
             outTexture.write(inTexture2.sample(sampler, uv), grid);
             return;
         }
         
         float2 center = float2(-0.1,1.1);
         //中心点移动方向速度 移动完后rectcenter=rectcenter+rectmove；
         float2 move = float2(0.6,-0.6);
         float2 movecenter = float2(0.0);
         float2 moveleft = float2(0.0);
         float2 moveright = float2(0.0);
         
         
         float useprogress = getresetpro(progress * 0.4+0.2);
         center += move * useprogress;
         
         //fun setpoints in t_roate_triangle2.glsl
         float length = useprogress * 1.4;
         float roate = PI * length;
         if(ratio > 1.0){
             length = length * ratio + 0.05;
         }
         movecenter = float2(0.0, length);
         movecenter= doroate(movecenter,-roate, ratio);
         moveleft = doroate(movecenter, PI*(0.66), ratio);
         moveright = doroate(movecenter, -PI*(0.66), ratio);
         float isin = isin_triangle(uv, center + movecenter, center + moveleft, center + moveright) ? 1.0 : 0.0;
        
         
         center = float2(0.5);
         float2 useto = center + (uv - center) * (1.0 - (useprogress - 1.0) * 0.2);
         useto = resetuse(useto);
         float4 out= mix(
                         inTexture1.sample(sampler, uv),
                         inTexture2.sample(sampler, useto),
                         isin
                         );
         outTexture.write(out, grid);
     }
}
