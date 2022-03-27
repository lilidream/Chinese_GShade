// Translation of the UI into Chinese by Lilidream.
// Lightly optimized by Marot Satil for the GShade project.
#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float3 fUIColor<
    ui_type = "color";
    ui_label = "颜色";
> = float3(0.1, 0.0, 0.3);

uniform float fUIStrength<
    ui_type = "slider";
    ui_label = "强度";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

float3 RetroTintPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    //Blend mode: Screen
#if GSHADE_DITHER
    const float3 outcolor = lerp(color, 1.0 - (1.0 - color) * (1.0 - fUIColor), fUIStrength);
    return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
    return lerp(color, 1.0 - (1.0 - color) * (1.0 - fUIColor), fUIStrength);
#endif
}

technique RetroTint <ui_label="怀旧色调";> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = RetroTintPS;
        /* RenderTarget = BackBuffer */
    }
}