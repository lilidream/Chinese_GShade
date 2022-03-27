/*
	SSAO by Constantine 'MadCake' Rudenko
 
		based on HBAO (Horizon Based Ambient Occlusion)
		https://developer.download.nvidia.com/presentations/2008/SIGGRAPH/HBAO_SIG08b.pdf
		https://developer.nvidia.com/sites/default/files/akamai/gameworks/samples/DeinterleavedTexturing.pdf

	License: https://creativecommons.org/licenses/by/4.0/
	CC BY 4.0

	You are free to:

	Share — copy and redistribute the material in any medium or format

	Adapt — remix, transform, and build upon the material
	for any purpose, even commercially.

	The licensor cannot revoke these freedoms as long as you follow the license terms.

	Under the following terms:

	Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. 
	You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

	No additional restrictions — You may not apply legal terms or technological measures 
	that legally restrict others from doing anything the license permits.
*/
// Translation of the UI into Chinese by Lilidream.

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 16.0; ui_step = 0.1;
	ui_tooltip = "效果强度(推荐 1.0 到 2.0)";
	ui_label = "强度";
> = 1.4;

uniform int SampleDistance <
	ui_type = "slider";
	ui_min = 1; ui_max = 64;
	ui_tooltip = "采样圆盘半径(像素)。推荐:32";
	ui_label = "采样圆盘半径";
> = 32.0;

uniform int Quality <
	ui_type = "combo";
	ui_label = "采样总数";
	ui_tooltip = "高的值产生更好的质量但要消耗性能，推荐: 8";
	ui_items = "采样数: 4\0采样数: 8\0采样数: 16\0采样数: 24\0采样数: 32\0采样数: 36\0采样数: 48\0采样数: 64\0";
> = 1;

uniform float StartFade <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 300.0; ui_step = 0.1;
	ui_tooltip = "当Z差值大于此值时，环境光开始淡化，必须大于 \"Z差值结束淡化\"。\n推荐: 0.4";
	ui_label = "Z差值开始淡化";
> = 0.4;

uniform float EndFade <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 300.0; ui_step = 0.1;
	ui_tooltip = "当Z差值大于此值时，环境光完全消失，必须小于\"Z差值开始淡化\"\n推荐: 0.6";
	ui_label = "Z差值结束淡化";
> = 0.6;

uniform float NormalBias <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.025;
	ui_tooltip = "防止自身遮蔽(推荐 0.1)";
	ui_label = "法线偏离";
> = 0.1;

uniform int DebugEnabled <
    ui_type = "combo";
    ui_label = "开启Debug视角";
    ui_items = "关闭\0模糊后\0模糊前\0";
> = 0;

uniform int Bilateral <
    ui_type = "combo";
    ui_label = "假双边滤镜\n推荐: \"关闭\" 来达到最高性能, \"水平优先\" 来达到更高质量。";
    ui_items = "关闭 (要求低，更模糊)\0垂直优先\0水平优先\0";
> = 2;

uniform int BlurRadius <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 32.0;
	ui_tooltip = "模糊半径(像素单位)\n推荐: 3 或 4";
	ui_label = "模糊半径";
> = 3.0;

uniform float BlurQuality <
		ui_type = "slider";
		ui_min = 0.5; ui_max = 1.0; ui_step = 0.1;
		ui_label = "模糊质量";
		ui_tooltip = "模糊质量(推荐 0.6)";
> = 0.6;

uniform float Gamma <
		ui_type = "slider";
		ui_min = 1.0; ui_max = 4.0; ui_step = 0.1;
		ui_label = "Gamma";
        ui_tooltip = "推荐 2.2\n(假设贴图在存储时应用了伽马值)";
> = 2.2;

uniform float NormalPower <
		ui_type = "slider";
		ui_min = 0.5; ui_max = 8.0; ui_step = 0.1;
		ui_label = "法线强度";
        ui_tooltip = "就像柔和版的法线偏差，没有阈值的作用\n推荐: 1.4";
> = 1.4;

uniform int FOV <
		ui_type = "slider";
		ui_min = 40; ui_max = 180; ui_step = 1.0;
		ui_label = "视野大小";
        ui_tooltip = "无论你的实际视野大小(FOV)是多少，把它放在90的位置都能提供可靠的结果。";
> = 90;

uniform float DepthShrink <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
		ui_label = "深度收缩";
        ui_tooltip = "更高的数值会使环境光遮蔽在远处的物体上变得更细。\n推荐: 0.65";
> = 0.65;


// DepthStartFade does not change much visually

/*
uniform float DepthStartFade <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 4000.0; ui_step = 1.0;
		ui_label = "Depth start fade";
        ui_tooltip = "Start fading AO at this Z value";
> = 0.0;
*/

uniform int DepthEndFade <
		ui_type = "slider";
		ui_min = 0; ui_max = 4000;
		ui_label = "淡化深度";
        ui_tooltip = "在此Z值时环境光遮蔽完全消失。\n推荐: 1000";
> = 1000;


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

texture2D InterleavedAOTex  { Width = BUFFER_WIDTH / 2;   Height = BUFFER_HEIGHT / 2;   Format = R8; MipLevels = 1;};
texture2D InterleavedAOTex2 { Width = BUFFER_WIDTH / 2;   Height = BUFFER_HEIGHT / 2;   Format = R8; MipLevels = 1;};
texture2D InterleavedAOTex3 { Width = BUFFER_WIDTH / 2;   Height = BUFFER_HEIGHT / 2;   Format = R8; MipLevels = 1;};
texture2D InterleavedAOTex4 { Width = BUFFER_WIDTH / 2;   Height = BUFFER_HEIGHT / 2;   Format = R8; MipLevels = 1;};

texture2D AOTex	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R8; MipLevels = 1;};
texture2D AOTex2	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R8; MipLevels = 1;};
texture2D NormalTex	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = 1;};

sampler2D sAOTex { Texture = AOTex; };
sampler2D sAOTex2 { Texture = AOTex2; };
sampler2D sInterleavedAOTex { Texture = InterleavedAOTex; };
sampler2D sInterleavedAOTex2 { Texture = InterleavedAOTex2; };
sampler2D sInterleavedAOTex3 { Texture = InterleavedAOTex3; };
sampler2D sInterleavedAOTex4 { Texture = InterleavedAOTex4; };
sampler2D sNormalTex { Texture = NormalTex; };

float GetTrueDepth(float2 coords)
{
	return ReShade::GetLinearizedDepth(coords) * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
}

float3 GetPosition(float2 coords)
{
	float2 fov;
	fov.x = FOV / 180.0 * 3.1415;
	fov.y = fov.x / BUFFER_ASPECT_RATIO; 
	float3 pos;
	pos.z = GetTrueDepth(coords.xy);
	coords.y = 1.0 - coords.y;
	pos.xy = coords.xy * 2.0 - 1.0;
	pos.xy /= float2(1.0 / tan(fov.x * 0.5), 1.0 / tan(fov.y * 0.5)) / pos.z;
	return pos;
}

float4 GetNormalFromDepth(float2 coords) 
{
	const float3 centerPos = GetPosition(coords);

	const float2 offx = float2(BUFFER_PIXEL_SIZE.x, 0);
	const float2 offy = float2(0, BUFFER_PIXEL_SIZE.y);

	return float4(normalize(cross((GetPosition(coords + offx) - centerPos) + (centerPos - GetPosition(coords - offx)), (GetPosition(coords + offy) - centerPos) + (centerPos - GetPosition(coords - offy)))), centerPos.z);
}

float4 GetNormalFromTexture(float2 coords)
{
	float4 normal = tex2Dlod(sNormalTex, float4(coords, 0.0, 0.0));
	normal.xyz = normal.xyz * 2.0 - float3(1,1,1);
	return normal;
}

float4 DepthNormalsPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 normal = GetNormalFromDepth(texcoord);
	normal.xyz = normal.xyz * 0.5 + 0.5;
	return normal;
}

float rand2D(float2 uv){
	uv = frac(uv);
	return frac(cos((frac(cos(uv.x*64)*256)+frac(cos(uv.y*137)*241))*107)*269);
}

float BlurAOFirstPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	if (clamp(DebugEnabled, 0, 2) == 2)
	{
		return tex2D(sAOTex, texcoord).r;
	}

	const float normal_bias = clamp(NormalBias, 0.0, 1.0);
	const int bilateral = clamp(Bilateral, 0, 2);

	float range = clamp(BlurRadius, 1, 32);
	const float fade_range = EndFade - StartFade;

	const float tmp = 1.0 / (range * range);
	float gauss = 1.0;
	float helper = exp(tmp * 0.5);
	const float helper2 = exp(tmp);
	float sum = tex2D(sAOTex, texcoord).r;
	float sumCoef = 1.0;

	range *= 3.0 * clamp(BlurQuality, 0.0, 1.0);

	float2 off = float2(BUFFER_PIXEL_SIZE.x, 0);
	
	float4 my_normal;

	if (bilateral)
	{
		my_normal = GetNormalFromTexture(texcoord);
	}

	if (Bilateral == 2)
	{
		off = float2(0, BUFFER_PIXEL_SIZE.y);
	}

	float weights[32];
	weights[0] = 1;
	
	[unroll]
	for (int i = 1; i < 32; i++)
	{
		gauss = gauss / helper;
		helper = helper * helper2;
		weights[i] = gauss;
	}
	
	[loop]
	for(int k = 1; k < range; k++)
	{
		float weight = weights[abs(k)];
		
		if (bilateral)
		{
			float4 normal = GetNormalFromTexture(texcoord + off * k);
			weight *= saturate((dot(my_normal.xyz, normal.xyz) - normal_bias) / (1.0 - normal_bias));
			float zdiff = abs(my_normal.w - normal.w);
			if (zdiff >= StartFade)
			{
				float fade = saturate(1.0 - (zdiff - StartFade) / fade_range);
				weight *= fade * fade;
			}
			sum += tex2Dlod(sAOTex, float4(texcoord + off * k, 0.0, 0.0)).r * weight;
			sumCoef += weight;
		}
		else
		{
			sum += tex2Dlod(sAOTex, float4(texcoord + off * k, 0.0, 0.0)).r * weight;
			sumCoef += weight;
		}
	}
	
	[loop]
	for(int k = 1; k < range; k++)
	{
		float weight = weights[abs(k)];

		if (bilateral)
		{
			float4 normal = GetNormalFromTexture(texcoord + off * k);
			normal *= pow(saturate((dot(my_normal.xyz, normal.xyz) - normal_bias) / (1.0 - normal_bias)), NormalPower);
			weight *= max(0.0, dot(my_normal.xyz, normal.xyz));
			float zdiff = abs(my_normal.w - normal.w);
			if (zdiff >= StartFade)
			{
				float fade = saturate(1.0 - (zdiff - StartFade) / fade_range);
				weight *= fade * fade;
			}
			sum += tex2Dlod(sAOTex, float4(texcoord - off * k, 0.0, 0.0)).r * weight;
			sumCoef += weight;
		}
		else
		{
			sum += tex2Dlod(sAOTex, float4(texcoord - off * k, 0.0, 0.0)).r * weight;
			sumCoef += weight;
		}
	}
	
	return sum / sumCoef;
}


float3 BlurAOSecondPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	int debugEnabled = clamp(DebugEnabled, 0, 2);
	if (debugEnabled == 2)
	{
		return tex2D(sAOTex2, texcoord).r;
	}

	const int bilateral = clamp(Bilateral, 0, 2);
	const float normal_bias = clamp(NormalBias, 0.0, 1.0);

	float range = clamp(BlurRadius, 1, 32);
	const float fade_range = EndFade - StartFade;

	const float tmp = 1.0 / (range * range);
	float gauss = 1.0;
	float helper = exp(tmp * 0.5);
	const float helper2 = exp(tmp);
	float sum = tex2D(sAOTex, texcoord).r;
	float sumCoef = 1.0;

	range *= 3.0 * clamp(BlurQuality, 0.0, 1.0);

	float2 off = float2(0, BUFFER_PIXEL_SIZE.y);

	float4 my_normal;

	if (bilateral)
	{
		my_normal = GetNormalFromTexture(texcoord);
	}

	if (Bilateral == 2)
	{
		off = float2(BUFFER_PIXEL_SIZE.x, 0);
	}

	float weights[32];
	weights[0] = 1;

	[unroll]
	for (int i = 1; i < 32; i++)
	{
		gauss = gauss / helper;
		helper = helper * helper2;
		weights[i] = gauss;
	}

	[loop]
	for(int k = 1; k < range; k++)
	{
		float weight = weights[abs(k)];

		if (bilateral)
		{
			float4 normal = GetNormalFromTexture(texcoord + off * k);
			weight *= max(0.0, dot(my_normal.xyz, normal.xyz));
			float zdiff = abs(my_normal.w - normal.w);
			zdiff *= zdiff;
			if (zdiff >= StartFade)
			{
				float fade = saturate(1.0 - (zdiff - StartFade) / fade_range);
				weight *= fade * fade;
			}
			sum += tex2Dlod(sAOTex2, float4(texcoord + off * k, 0.0, 0.0)).r * weight;
			sumCoef += weight;
		}
		else
		{
			sum += tex2Dlod(sAOTex2, float4(texcoord + off * k, 0.0, 0.0)).r * weight;
			sumCoef += weight;
		}
	}

	[loop]
	for(int k = 1; k < range; k++)
	{
		float weight = weights[abs(k)];

		if (bilateral)
		{
			float4 normal = GetNormalFromTexture(texcoord - off * k);
			normal *= pow(saturate((dot(my_normal.xyz, normal.xyz) - normal_bias) / (1.0 - normal_bias)), NormalPower);
			weight *= saturate((dot(my_normal.xyz, normal.xyz) - normal_bias) / (1.0 - normal_bias));
			float zdiff = abs(my_normal.w - normal.w);
			if (zdiff >= StartFade)
			{
				float fade = saturate(1.0 - (zdiff - StartFade) / fade_range);
				weight *= fade * fade;
			}
			sum += tex2Dlod(sAOTex2, float4(texcoord - off * k, 0.0, 0.0)).r * weight;
			sumCoef += weight;
		}
		else
		{
			sum += tex2Dlod(sAOTex2, float4(texcoord - off * k, 0.0, 0.0)).r * weight;
			sumCoef += weight;
		}
	}

	if (debugEnabled)
	{
		return sum / sumCoef;
	}
	else
	{
#if GSHADE_DITHER
		const float3 outcolor = tex2D(ReShade::BackBuffer, texcoord).rgb * sum / sumCoef;
		return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
		return tex2D(ReShade::BackBuffer, texcoord).rgb * sum / sumCoef;
#endif
	}
}

float2 ensure_1px_offset(float2 ray)
{
	const float2 ray_in_pixels = ray / BUFFER_PIXEL_SIZE;
	const float coef = max(abs(ray_in_pixels.x), abs(ray_in_pixels.y));
	if (coef < 1.0)
	{
		ray /= coef;
	}
	return ray;
}

float3 MergeAOPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	uint2 texcoord_px = texcoord / BUFFER_PIXEL_SIZE;
	
	/*
	if (texcoord_px.x % 2 && texcoord_px.y % 2)
		return 0;
	if (texcoord_px.x % 2)
		return float3(1,0,0);
	if (texcoord_px.y % 2)
		return float3(0,1,0);
	return float3(0,0,1);*/
	
	if (texcoord_px.x % 2 && texcoord_px.y % 2)
		return tex2D(sInterleavedAOTex4, texcoord).r;
	if (texcoord_px.x % 2)
		return tex2D(sInterleavedAOTex2, texcoord).r;
	if (texcoord_px.y % 2)
		return tex2D(sInterleavedAOTex3, texcoord).r;
	return tex2D(sInterleavedAOTex, texcoord).r;
}

float GetOcclusion(float2 texcoord, float angle_jitter)
{
	const float3 position = GetPosition(texcoord);
	const float3 normal = GetNormalFromTexture(texcoord).xyz;

	int num_angle_samples;
	int num_distance_samples;

	switch(clamp(Quality, 0, 7))
	{
		case 0:
			num_angle_samples = 4;
			num_distance_samples = 1;
			break;
		case 1:
			num_angle_samples = 4;
			num_distance_samples = 2;
			break;
		case 2:
			num_angle_samples = 4;
			num_distance_samples = 4;
			break;
		case 3:
			num_angle_samples = 6;
			num_distance_samples = 4;
			break;
		case 4:
			num_angle_samples = 8;
			num_distance_samples = 4;
			break;
		case 5:
			num_angle_samples = 6;
			num_distance_samples = 6;
			break;
		case 6:
			num_angle_samples = 8;
			num_distance_samples = 6;
			break;
		case 7:
			num_angle_samples = 8;
			num_distance_samples = 8;
			break;
	}

	const int sample_dist = clamp(SampleDistance, 1, 128);
	const float normal_bias = clamp(NormalBias, 0.0, 1.0);

	float occlusion = 0.0;
	const float fade_range = EndFade - StartFade;

	[loop]
	for (int i = 0; i < num_angle_samples; i++)
	{
		float angle = 3.1415 * 2.0 / num_angle_samples * (i + angle_jitter);
		
		float2 ray;
		ray.x = sin(angle);
		ray.y = cos(angle);
		ray *= BUFFER_PIXEL_SIZE * sample_dist;
		ray /= 1.0 + position.z * lerp(0, 0.05, pow(max(DepthShrink, 0.0),4));
		
		float angle_occlusion = 0.0;
		
		[loop]
		for (int k = 0; k < num_distance_samples; k++)
		{
			float3 v = GetPosition(texcoord + ensure_1px_offset(ray * max((k + 1.0 - rand2D(texcoord + float2(i, 0))) / num_distance_samples, 0.01))) - position;
			float ray_occlusion = saturate((pow(max(dot(normal.xyz, normalize(v)), 0.0), NormalPower) - normal_bias) / (1.0 - normal_bias));
			float zdiff = abs(v.z);
			if (zdiff >= StartFade)
			{
				float fade = saturate(1.0 - (zdiff - StartFade) / fade_range);
				ray_occlusion *= fade * fade;
			}

			float fade_coef = float(num_distance_samples - k) / num_distance_samples;
			fade_coef *= fade_coef;
			angle_occlusion = max(angle_occlusion, ray_occlusion * fade_coef);
		}
		
		occlusion += angle_occlusion;
	}

	return pow(max(saturate(1.0 - ((occlusion / num_angle_samples * 2.0) * saturate(1.0 - (position.z / DepthEndFade))) * Strength), 0.0), Gamma);
}

void SSAOPass(float4 vpos : SV_Position, in float2 texcoord : TexCoord,
				out float occlusion_1 : SV_Target0, out float occlusion_2 : SV_Target1, out float occlusion_3 : SV_Target2, out float occlusion_4 : SV_Target3)
{
	occlusion_1 = GetOcclusion(texcoord + float2(-0.25,  0.25) * BUFFER_PIXEL_SIZE,  0.00);
	occlusion_2 = GetOcclusion(texcoord + float2( 0.25,  0.25) * BUFFER_PIXEL_SIZE,  0.25);
	occlusion_3 = GetOcclusion(texcoord + float2(-0.25, -0.25) * BUFFER_PIXEL_SIZE,  0.50);
	occlusion_4 = GetOcclusion(texcoord + float2( 0.25, -0.25) * BUFFER_PIXEL_SIZE,  0.75);
}

technique MC_DAO <ui_label="MC屏幕环境光遮蔽(SSAO)";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DepthNormalsPass;
		RenderTarget0 = NormalTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = SSAOPass;
		RenderTarget0 = InterleavedAOTex;
		RenderTarget1 = InterleavedAOTex2;
		RenderTarget2 = InterleavedAOTex3;
		RenderTarget3 = InterleavedAOTex4;
	}
	pass 
	{
		VertexShader = PostProcessVS;
		PixelShader = MergeAOPass;
		RenderTarget0 = AOTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BlurAOFirstPass;
		RenderTarget0 = AOTex2;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BlurAOSecondPass;
	}
}
