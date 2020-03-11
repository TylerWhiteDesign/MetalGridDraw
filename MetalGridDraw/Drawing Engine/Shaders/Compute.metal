//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "../../Common.h"

kernel void compute_matrix(device CellInstanceAttributes *cellInstanceAttributesArray [[buffer(0)]], constant uint &totalCount [[buffer(1)]], uint id [[thread_position_in_grid]]) {
    if (id + 1 > totalCount) {
        return;
    }
    CellInstanceAttributes cellInstance = cellInstanceAttributesArray[id];
    float2 center = cellInstance.center;
    
    float4x4 translationMatrix = {
        {1, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 0, 1, 0},
        {center.x, center.y, 0, 1}
    };
    float4x4 translationMatrixInverse = {
        {1, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 0, 1, 0},
        {-center.x, -center.y, 0, 1}
    };
    float4x4 translationScaleMatrix = translationMatrix * cellInstance.scaleMatrix * translationMatrixInverse;
    float4x4 modelMatrix = translationScaleMatrix * translationMatrix;
    cellInstanceAttributesArray[id].modelMatrix = modelMatrix;
}

kernel void compute_hit(device CellInstanceAttributes *cellInstanceAttributesArray [[buffer(0)]], constant uint &totalCount [[buffer(1)]], device uint &hitIndex [[buffer(2)]], constant float2 &testPoint [[buffer(3)]], constant float &dimension [[buffer(4)]], uint id [[thread_position_in_grid]]) {
    if (hitIndex != 0 || id >= totalCount) {
        return;
    }
    
    CellInstanceAttributes cellInstance = cellInstanceAttributesArray[id];
    float2 center = cellInstance.center;
    float halfDimension = dimension / 2;
    
    if (testPoint.x < center.x + halfDimension && testPoint.x > center.x - halfDimension && testPoint.y < center.y + halfDimension && testPoint.y > center.y - halfDimension) {
        hitIndex = id + 1;
    }
}
