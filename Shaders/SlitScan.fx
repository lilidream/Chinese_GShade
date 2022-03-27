/*-----------------------------------------------------------------------------------------------------*/
/* Slit Scan Shader v1.1 - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
// Translation of the UI into Chinese by Lilidream.
#include "ReShade.fxh";

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float x_col <
    ui_type = "slider";
    ui_label = "位置";
    ui_tooltip = "决定屏幕的哪一列开始扫描";
    ui_max = 1.0;
    ui_min = 0.0;
> = 0.250;

uniform float scan_speed <
    ui_type = "slider";
    ui_label="扫描速度";
    ui_tooltip=
        "调整扫描的速度。较低的值意味着较慢的扫描，这可以在牺牲扫描速度的情况下得到更好的图像。";
    ui_max = 3.0;
    ui_min = 0.0;
> = 1.0;

uniform float min_depth <
    ui_type = "slider";
    ui_label="最小深度";
    ui_tooltip="在设定的深度之前，取消任何东西的遮罩。";
    ui_min=0.0;
    ui_max=1.0;
> = 0;

uniform int direction <
    ui_type = "combo";
    ui_label = "扫描方向";
    ui_items = "左\0右\0上\0下\0";
    ui_tooltip = "改变扫描的方向";
> = 0;

uniform int animate <
    ui_type = "combo";
    ui_label = "动画";
    ui_items = "关\0开\0";
    ui_tooltip = "使扫描列动起来，从一端到另一端";
> = 0;

uniform float frame_rate <
    source = "framecount";
>;

uniform float2 anim_rate <
    source = "pingpong";
    min = 0.0;
    max = 1.0;
    step = 0.001;
    smoothing = 0.0;
>;

texture texColorBuffer: COLOR;

texture ssTexture {
    Height = BUFFER_HEIGHT;
    Width = BUFFER_WIDTH;
};

sampler samplerColor {
    Texture = texColorBuffer;

    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16;
    
};

sampler ssTarget {
    Texture = ssTexture;
        
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;

    Height = BUFFER_HEIGHT;
    Width = BUFFER_WIDTH;
    Format = RGBA16;
};

float get_pix_w() {
    float output;
    switch(direction) {
        case 0:
        case 1:
            output = scan_speed * BUFFER_RCP_WIDTH;
            break;
        case 2:
        case 3:
            output = scan_speed * BUFFER_RCP_HEIGHT;
            break;
    }
    return output;
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
};

void SlitScan(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_TARGET)
{
    float4 col_pixels;
    float scan_col;

    if(animate) scan_col = anim_rate.x;
    else scan_col = x_col;

    switch(direction) {
        case 0:
        case 1:
            col_pixels =  tex2D(samplerColor, float2(scan_col, texcoord.y));
            break;
        case 2:
        case 3:
            col_pixels =  tex2D(samplerColor, float2(texcoord.x, scan_col));
            break;

    } 
    float pix_w = get_pix_w();
    float slice_to_fill;
    switch(direction){
        case 0:
        case 2:
            slice_to_fill = (frame_rate * pix_w) % 1;
            break;
        case 1:
        case 3:
            slice_to_fill = abs(1-((frame_rate * pix_w) % 1));
            break;
    } 

    float4 cols = tex2Dfetch(ssTarget, texcoord);
    float4 col_to_write = tex2Dfetch(ssTarget, texcoord);
    switch(direction) {
        case 0:
        case 1:
            if(texcoord.x >= slice_to_fill - pix_w && texcoord.x <= slice_to_fill + pix_w)
                col_to_write.rgba = col_pixels.rgba;
            else
                discard;
            break;
        case 2:
        case 3:
            if(texcoord.y >= slice_to_fill - pix_w && texcoord.y <= slice_to_fill + pix_w)
                col_to_write.rgba = col_pixels.rgba;
            else
                discard;
            break;
    }
    
    color = col_to_write;
};

void SlitScanPost(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_TARGET)
{
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float2 uv = texcoord;
    float4 screen = tex2D(samplerColor, texcoord);
    float pix_w = get_pix_w();
    float scan_col;
    
    if(animate) scan_col = anim_rate.x;
    else scan_col = x_col;

    switch(direction) {
        case 0:
            uv.x +=  (frame_rate * pix_w) - scan_col % 1 ;
            break;
        case 1:
            uv.x -= (frame_rate * pix_w) - (1 - scan_col) % 1 ;
            break;
        case 2:
            uv.y +=  (frame_rate * pix_w) - scan_col % 1 ;
            break;
        case 3:
            uv.y -=  (frame_rate * pix_w) - (1 - scan_col) % 1 ;
            break;
    }
    
    float4 scanned = tex2D(ssTarget, uv);


    float4 mask;
    switch(direction) {
        case 0:
            mask = step(texcoord.x, scan_col);
            break;
        case 1:
            mask = step(scan_col, texcoord.x);
            break;
        case 2:
            mask = step(texcoord.y, scan_col);
            break;
        case 3:
            mask = step(scan_col, texcoord.y);
            break;
    }
    if(depth >= min_depth)
        color = lerp(screen, scanned, mask);
    else
        color = screen;

#if GSHADE_DITHER
	color.rgb += TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}



technique SlitScan <
ui_label="切割扫描";
> {
    pass p0 {

        VertexShader = FullScreenVS;
        PixelShader = SlitScan;
        
        RenderTarget = ssTexture;
    }

    pass p1 {

        VertexShader = FullScreenVS;
        PixelShader = SlitScanPost;

    }
}