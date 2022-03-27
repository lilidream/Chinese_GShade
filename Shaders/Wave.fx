/*-----------------------------------------------------------------------------------------------------*/
/* Wave Shader - by Radegast Stravinsky of Ultros.                                                */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
// Translation of the UI into Chinese by Lilidream.
#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform int wave_type <
    ui_type = "combo";
    ui_label = "波浪类型";
    ui_tooltip = "选择应用的扭曲类型";
    ui_items = "X/X\0X/Y\0";
    ui_tooltip = "应针对哪个轴进行变形。";
> = 1;

uniform float angle <
    ui_type = "slider";
    ui_label = "角度";
    ui_tooltip = "扭曲出现的角度";
    ui_min = -360.0; 
    ui_max = 360.0; 
    ui_step = 1.0;
> = 0.0;

uniform float period <
    ui_type = "slider";
    ui_label = "周期";
    ui_min = 0.1; 
    ui_max = 10.0;
    ui_tooltip = "扭曲的波长。越小的值产生越长的波长。";
> = 3.0;

uniform float amplitude <
    ui_type = "slider";
    ui_label = "振幅";
    ui_min = -1.0; 
    ui_max = 1.0;
    ui_tooltip = "各个方向上扭曲的振幅";
> = 0.075;

uniform float phase <
    ui_type = "slider";
    ui_label = "相位";
    ui_min = -5.0; 
    ui_max = 5.0;
    ui_tooltip = "被应用于扭曲的波的偏移。";
> = 0.0;

uniform float depth_threshold <
    ui_type = "slider";
    ui_label="深度阈值";
    ui_category = "深度";
    ui_min=0.0;
    ui_max=1.0;
> = 0;

uniform int depth_mode <
    ui_type = "combo";
    ui_label = "深度模式";
    ui_category = "深度";
    ui_items = "最小值\0最大值\0";
    ui_tooltip = "通过场景深度遮罩效果。";
> = 0;

uniform bool set_max_depth_behind <
    ui_label = "设置扭曲在前景之后";
    ui_tooltip = "(仅最大值深度阈值模式) 启用后，将扭曲的区域设置在应在其前面的物体后面。";
    ui_category = "深度";
> = 0;


uniform int animate <
    ui_type = "combo";
    ui_label = "动画";
    ui_items = "无\0振幅\0相位\0角度\0";
    ui_tooltip = "启用或停用动画。通过相位、振幅或角度对波浪效果进行动画。";
> = 0;

uniform float anim_rate <
    source = "timer";
>;

BLENDING_COMBO(
    render_type, 
    "混合模式", 
    "让效果与前面的图层混合",
    "混合",
    false,
    0,
    0
);

uniform float blending_amount <
    ui_type = "slider";
    ui_label = "透明度";
    ui_category = "混合";
    ui_tooltip = "调整混合数量";
    ui_min = 0.0;
    ui_max = 1.0;
> = 1.0;

texture texColorBuffer : COLOR;

sampler samplerColor
{
    Texture = texColorBuffer;

    AddressU = MIRROR;
    AddressV = MIRROR;
    AddressW = MIRROR;

    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;

    MinLOD = 0.0f;
    MaxLOD = 1000.0f;

    MipLODBias = 0.0f;

    SRGBTexture = false;
};

// Vertex Shader
void FullScreenVS(uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    if (id == 2)
        texcoord.x = 2.0;
    else
        texcoord.x = 0.0;

    if (id == 1)
        texcoord.y  = 2.0;
    else
        texcoord.y = 0.0;

    position = float4( texcoord * float2(2, -2) + float2(-1, 1), 0, 1);

}

float4 Wave(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET 
{
    
    const float ar = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    const float2 center = float2(0.5 / ar, 0.5);
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float2 tc = texcoord;
    const float4 base = tex2D(samplerColor, texcoord);
    float4 color;

    tc.x /= ar;

    const float theta = radians(animate == 3 ? (anim_rate * 0.01 % 360.0) : angle);
    const float s =  sin(theta);
    const float _s = sin(-theta);
    const float c =  cos(theta);
    const float _c = cos(-theta);

    tc = float2(dot(tc - center, float2(c, -s)), dot(tc - center, float2(s, c)));

    if(wave_type == 0)
    {
        switch(animate)
        {
            default:
                tc.x += amplitude * sin((tc.x * period * 10) + phase);
                break;
            case 1:
                tc.x += (sin(anim_rate * 0.001) * amplitude) * sin((tc.x * period * 10) + phase);
                break;
            case 2:
                tc.x += amplitude * sin((tc.x * period * 10) + (anim_rate * 0.001));
                break;
        }
    }
    else
    {
        switch(animate)
        {
            default:
                tc.x +=  amplitude * sin((tc.y * period * 10) + phase);
                break;
            case 1:
                tc.x += (sin(anim_rate * 0.001) * amplitude) * sin((tc.y * period * 10) + phase);
                break;
            case 2:
                tc.x += amplitude * sin((tc.y * period * 10) + (anim_rate * 0.001));
                break;
        }
    }
    tc = float2(dot(tc, float2(_c, -_s)), dot(tc, float2(_s, _c))) + center;

    tc.x *= ar;

    color = tex2D(samplerColor, tc);
    float blending_factor;
    if(render_type)
        blending_factor = lerp(0, abs(amplitude)* lerp(10, 1, abs(amplitude)), blending_amount);
    else
        blending_factor = blending_amount;
    
    color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);


    float out_depth;
    bool inDepthBounds;
    if ( depth_mode == 0) {
        out_depth =  ReShade::GetLinearizedDepth(texcoord).r;
        inDepthBounds = out_depth >= depth_threshold;
    } else {
        out_depth = ReShade::GetLinearizedDepth(tc).r;
        inDepthBounds = out_depth <= depth_threshold;
    }

    if(inDepthBounds){
        color = tex2D(samplerColor, tc);
    
        color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
    }
    else
    {
        color = tex2D(samplerColor, texcoord);
    }

    if(set_max_depth_behind) {
        const float mask_front = ReShade::GetLinearizedDepth(texcoord).r;
        if(mask_front < depth_threshold)
            color = tex2D(samplerColor, texcoord);
    }
    return color;
}

technique Wave <ui_label="波";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = Wave;
    }
}
