//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "../../Common.h"

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 color;
};

vertex VertexOut vertex_main(const VertexIn vertex_in [[stage_in]], constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut vertex_out {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vertex_in.position
    };
    return vertex_out;
}

fragment float4 fragment_main(VertexOut vertex_in [[stage_in]], constant FragmentUniforms &fragmentUniforms [[buffer(0)]]) {
    return float4(fragmentUniforms.color, 1);
}

vertex VertexOut vertex_instances(const VertexIn vertex_in [[stage_in]], constant Uniforms &uniforms [[buffer(1)]], constant CellInstanceAttributes *instances [[buffer(2)]], uint instanceID [[instance_id]]) {
    CellInstanceAttributes instanceAttributes = instances[instanceID];
    
    VertexOut vertex_out {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * instanceAttributes.modelMatrix * vertex_in.position,
        .color = instanceAttributes.color
    };
    return vertex_out;
}

fragment float4 fragment_instances(VertexOut vertex_in [[stage_in]]) {
    return float4(vertex_in.color, 1);
}
