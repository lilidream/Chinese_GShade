/*-----------------------------------------------------------------------------------------------------*/
/* Swirl Shader - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
// Translation of the UI into Chinese by Lilidream.
#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform int swirl_mode <
    ui_type = "combo";
    ui_label = "模式";
    ui_items = "正常\0径向拼接\0";
    ui_tooltip="选择显示的涡旋模式。\n(正常模式）围绕一个点连续地扭曲像素。(径向拼接）创建渐进式旋转的圆形拼接。";
> = 0;

uniform float radius <
    ui_label= "半径";
    ui_tooltip = "扭曲的大小";
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float inner_radius <
    ui_type = "slider";
    ui_label = "内部半径";
    ui_tooltip = "(正常模式）设置自动设置最大角度的内半径。\n(径向拼接模式）定义最内侧拼接圆的大小。";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0;

uniform int number_splices <
        ui_type = "slider";
        ui_label = "(仅径向拼接模式)拼接数量";
        ui_tooltip = "(仅径向拼接模式)设定拼接的数量。一个较高的值使效果看起来更接近于正常模式，因为增加了拼接的数量。";
        ui_min = 1;
        ui_max = 50;
> = 10;


uniform float angle <
    ui_type = "slider";
    ui_label = "角度";
    ui_min = -1800.0; 
    ui_max = 1800.0; 
    ui_tooltip = "控制扭曲的角度";
    ui_step = 1.0;
> = 180.0;

uniform float tension <
    ui_type = "slider";
    ui_label = "张力";
    ui_min = 0; 
    ui_max = 10; 
    ui_step = 0.001;
    ui_tooltip="决定了漩涡达到最大角度的快慢。";
> = 1.0;

uniform float2 coordinates <
    ui_type = "slider";
    ui_label="坐标"; 
    ui_tooltip="(关闭使用偏移坐标)效果中心的X和Y位置。(开启使用偏移坐标)确定未失真的源上输出失真的坐标。";
    ui_min = 0.0; 
    ui_max = 1.0;
> = float2(0.25, 0.25);

uniform bool use_mouse_point <
    ui_label="使用鼠标坐标";
    ui_tooltip="开启时，使用鼠标坐标而不是定义的坐标。";
> = false;

uniform float aspect_ratio <
    ui_type = "slider";
    ui_label="纵横比"; 
    ui_min = -100.0; 
    ui_max = 100.0;
    ui_tooltip = "改变扭曲的纵横比以符合显示的纵横比";
> = 0;

uniform bool use_offset_coords <
    ui_label = "使用偏移坐标";
    ui_category = "偏移";
    ui_tooltip = "在其原始坐标之外的任何位置显示扭曲。";
> = 0;

uniform float2 offset_coords <
    ui_label = "偏移坐标";
    ui_tooltip = "(开启使用偏移坐标) 确定源坐标在传递到输出坐标时要被扭曲。.";
    ui_type = "slider";
    ui_category = "偏移";
    ui_min = 0.0;
    ui_max = 1.0;
> = float2(0.5, 0.5);

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
    ui_tooltip = "使用场景深度来遮罩效果";
> = 0;

uniform bool set_max_depth_behind <
    ui_label = "设置扭曲在前景之后";
    ui_tooltip = "(仅最大值深度阈值模式) 启用后，将扭曲的区域设置在应在其前面的物体后面。";
    ui_category = "深度";
> = 0;

uniform int animate <
    ui_type = "combo";
    ui_label = "动画";
    ui_items = "关\0开\0";
    ui_tooltip = "使旋涡动画化，顺时针与逆时针交替变化";
> = 0;

uniform int inverse <
    ui_type = "combo";
    ui_label = "反转角度";
    ui_items = "关\0开\0";
    ui_tooltip = "反转扭曲角度，使边缘达到最大扭曲程度。";
> = 0;

BLENDING_COMBO(
    render_type, 
    "混合模式", 
    "混合效果与前面的图层",
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

uniform float anim_rate <
    source = "timer";
>;

uniform float2 mouse_coordinates < 
source= "mousepoint";
>;

texture texColorBuffer : COLOR;

sampler samplerColor
{
    Texture = texColorBuffer;
    
    AddressU = MIRROR;
    AddressV = MIRROR;
    AddressW = MIRROR;

    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16;
};

float2x2 swirlTransform(float theta) {
    const float c = cos(theta);
    const float s = sin(theta);

    const float m1 = c;
    const float m2 = -s;
    const float m3 = s;
    const float m4 = c;

    return float2x2(
        m1, m2,
        m3, m4
    );
}

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

// Pixel Shaders (in order of appearance in the technique)
float4 Swirl(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);
    const float4 base = tex2D(samplerColor, texcoord);
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float2 center = coordinates / 2.0;
    float2 offset_center = offset_coords / 2.0;
    
    if (use_mouse_point) 
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH / 2.0, mouse_coordinates.y * BUFFER_RCP_HEIGHT / 2.0);

    float2 tc = texcoord - center;
    float4 color;

    center.x /= ar;
    offset_center.x /= ar;
    tc.x /= ar;

    
    const float dist = distance(tc, center);
    const float dist_radius = radius-dist;
    const float tension_radius = lerp(radius-dist, radius, tension);
    float percent; 
    float theta; 
       
    if(swirl_mode == 0){
        percent = max(dist_radius, 0) / tension_radius;   
        if(inverse && dist < radius)
            percent = 1 - percent;     
        
        if(dist_radius > radius-inner_radius)
            percent = 1;
        
        theta = percent * percent * radians(angle * (animate == 1 ? sin(anim_rate * 0.0005) : 1.0));
    }
    else
    {
        float splice_width = (tension_radius-inner_radius) / number_splices;
        splice_width = frac(splice_width);
        float cur_splice = max(dist_radius,0)/splice_width;
        cur_splice = cur_splice - frac(cur_splice);
        float splice_angle = (angle / number_splices) * cur_splice;
        if(dist_radius > radius-inner_radius)
            splice_angle = angle;
        theta = radians(splice_angle * (animate == 1 ? sin(anim_rate * 0.0005) : 1.0));
    }

    tc = mul(swirlTransform(theta), tc-center);

    if(use_offset_coords) 
        tc += (2 * offset_center);
    else 
        tc += (2 * center);

    tc.x *= ar;
      
    float out_depth;
    bool inDepthBounds;
    if (depth_mode == 0) 
    {
        out_depth =  ReShade::GetLinearizedDepth(texcoord).r;
        inDepthBounds = out_depth >= depth_threshold;
    }
    else
    {
        out_depth = ReShade::GetLinearizedDepth(tc).r;
        inDepthBounds = out_depth <= depth_threshold;
    }
         
    if (inDepthBounds)
    {
        if(use_offset_coords)
        {
            if((!swirl_mode && percent) || (swirl_mode && theta))
                color = tex2D(samplerColor, tc);
            else
                color = tex2D(samplerColor, texcoord);
        } else
            color = tex2D(samplerColor, tc);

        float blending_factor;
        if(swirl_mode)
            blending_factor = blending_amount;
        else {
            if(render_type)
                blending_factor = lerp(0, dist_radius * tension_radius * 10, blending_amount);
            else
                blending_factor = blending_amount;
        }
        if((!swirl_mode && percent) || (swirl_mode && dist <= radius))
            color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
            
    }
    else
    {
        color = base;
    }

    if(set_max_depth_behind) 
    {
        const float mask_front = ReShade::GetLinearizedDepth(texcoord).r;
        if(mask_front < depth_threshold)
            color = tex2D(samplerColor, texcoord);
    }

    return color;  
}

// Technique
technique Swirl< ui_label="旋涡";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = Swirl;
    }
};
