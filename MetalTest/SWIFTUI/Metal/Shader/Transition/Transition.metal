//
//  Shader.metal
//  MetalTest
//
//  Created by YUE on 2022/11/11.
//

#include <metal_stdlib>
using namespace metal;

// 光效2： 视频分两个盖上的
// 效果：  前5个在test分组已经实现  后边4个也写到那里
// 飞入：  10
// 折叠：  矩阵写的，计算函数无法实现
// 遮照：  1-7视频 其他下边已经实现
// 线性：  14
// 擦出：  3个视频
// 卡通：  12个视频

namespace Transition {
    
    struct TransitionPara {
        float percent;
    };
    
}


