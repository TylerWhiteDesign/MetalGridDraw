//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

typedef struct {
    vector_float3 color;
} FragmentUniforms;

typedef struct {
    vector_float2 center;
    matrix_float4x4 scaleMatrix;
    matrix_float4x4 modelMatrix;
    vector_float3 color;
} CellInstanceAttributes;

#endif /* Common_h */
