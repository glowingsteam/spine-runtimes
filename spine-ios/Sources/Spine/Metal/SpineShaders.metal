#include <metal_stdlib>

using namespace metal;

typedef enum SpineVertexInputIndex {
    SpineVertexInputIndexVertices     = 0,
    SpineVertexInputIndexTransform    = 1,
    SpineVertexInputIndexViewportSize = 2,
    SpineVertexInputIndexRGBTintData  = 3,
} SpineVertexInputIndex;

typedef enum SpineTextureIndex {
    SpineTextureIndexBaseColor = 0,
} SpineTextureIndex;

typedef struct {
    vector_float2 position;
    vector_float4 color;
    vector_float2 uv;
} SpineVertex;

typedef struct {
    vector_float2 translation;
    vector_float2 scale;
    vector_float2 offset;
} SpineTransform;

typedef struct {
    bool useRGB;
    float3 redTint;
    float3 greenTint;
    float3 blueTint;
} RGBTintData;

struct RasterizerData {
    float4 position [[position]];
    float4 color;
    float2 textureCoordinate;
    bool useRGB;
    float3 redTint;
    float3 greenTint;
    float3 blueTint;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant SpineVertex *vertices [[buffer(SpineVertexInputIndexVertices)]],
             constant SpineTransform *transform [[buffer(SpineVertexInputIndexTransform)]],
             constant vector_uint2 *viewportSizePointer [[buffer(SpineVertexInputIndexViewportSize)]],
             constant RGBTintData *rgbTintData [[buffer(SpineVertexInputIndexRGBTintData)]])
{
    RasterizerData out;

    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    
    out.position.xy = pixelSpacePosition;
    out.position.xy *= transform->scale;
    out.position.xy += transform->translation * transform->scale + transform->offset;
    out.position.xy /= viewportSize / 2;
    out.position.y *= -1;
    
    out.color = vertices[vertexID].color;
    out.textureCoordinate = vertices[vertexID].uv;
    
    // Pass RGB tint data to fragment shader
    out.useRGB = rgbTintData->useRGB;
    out.redTint = rgbTintData->redTint;
    out.greenTint = rgbTintData->greenTint;
    out.blueTint = rgbTintData->blueTint;

    return out;
}

fragment float4
fragmentShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(SpineTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::nearest,
                                      min_filter::nearest);
    
    half4 texColor = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    if (in.useRGB) {
        float3 originalColor = float3(texColor.rgb);
        float3 tintedColor = originalColor.r * in.redTint +
                             originalColor.g * in.greenTint +
                             originalColor.b * in.blueTint;
        texColor = half4(half3(tintedColor), texColor.a);
    }

    return float4(texColor) * in.color;
}