/*
	Oilify Shader for ReShade
	
	By: Lord of Lunacy
	
	This shader applies a Kuwahara filter using an optimized method for extracting the image mean and variance.
	
	Kuwahara filter. (2020, May 01). Retrieved October 17, 2020, from https://en.wikipedia.org/wiki/Kuwahara_filter
	
	Kyprianidis, J. E., Kang, H., &amp; Dã¶Llner, J. (2009). Image and Video Abstraction by Anisotropic Kuwahara Filtering.
	Computer Graphics Forum, 28(7), 1955-1963. doi:10.1111/j.1467-8659.2009.01574.x
*/
// Translation of the UI into Chinese by Lilidream.

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#ifndef OILIFY_SIZE
	#define OILIFY_SIZE 7
#endif
#ifndef OILIFY_ITERATIONS
	#define OILIFY_ITERATIONS 1
#endif
#define OILIFY_PASS \
		pass \
		{ \
			VertexShader = PostProcessVS;\
			PixelShader = KuwaharaPS;\
		}\
	
	static const float PI = 3.1415926536;
	static const float GAUSSIAN_WEIGHTS[5] = {0.095766,	0.303053,	0.20236,	0.303053,	0.095766};
	static const float GAUSSIAN_OFFSETS[5] = {-3.2979345488, -1.40919905099, 0, 1.40919905099, 3.2979345488};
	
namespace Oilify
{
	texture BackBuffer : COLOR;
	texture Anisotropy {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f;};

	sampler sBackBuffer{Texture = BackBuffer;};
	sampler sAnisotropy{Texture = Anisotropy;};

	uniform float Sharpness<
		ui_type = "slider";
		ui_label = "锐化";
		ui_tooltip = "设置更高得到锐化的图像, 低的值将使画面看起来更简化。";
		ui_min = 0; ui_max = 1;
		ui_step = 0.001;
	> = 1;

	uniform float Tuning<
		ui_type = "slider";
		ui_label = "各向异性调整";
		ui_tooltip = "调整各向异性取样的椭圆程度，数字越小意味着越椭圆。(如果着色器看起来被拉长了，就使用这个。）";
		ui_min = 0; ui_max = 4;
	> = 2;

	uniform float Scale<
		ui_type = "slider";
		ui_label = "缩放";
		ui_tooltip = "与大小类似，它提高了效果的应用范围，但是，样本的数量保持不变，导致图像的细节较少。";
		ui_min = 1; ui_max = 4;
	> = 1;

	// Vertex shader generating a triangle covering the entire screen
	void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

	void AnisotropyPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 anisotropyData : SV_TARGET0)
	{
		float3 center = tex2D(sBackBuffer, texcoord).rgb * 255;
		float3 dx = center * GAUSSIAN_WEIGHTS[2];
		float3 dy = dx;
		
		[unroll]
		for(int i = 0; i < 5; i++)
		{
			if (i == 2) i++;
			float3 offsets = float3(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, 0) * GAUSSIAN_OFFSETS[i];
			dx += tex2D(sBackBuffer, texcoord + offsets.xz).rgb * GAUSSIAN_WEIGHTS[i] * 255;
			dy += tex2D(sBackBuffer, texcoord + offsets.zy).rgb * GAUSSIAN_WEIGHTS[i] * 255;
		}
		
		float e = dot(dx, dx);
		float f = dot(dx, dy);
		float g = dot(dy, dy);
		float root = sqrt((e-g) * (e-g) + 4 * f * f);
		float2 eigenvalues = float2(e + g + root, e + g - root) / 2;
		
		float2 t;
		if(any(abs(float2(eigenvalues.x - e, -f)) > 1e-15))
		{
			t = (normalize((float2(eigenvalues.x - e, -f))));
		}
		else
			t = float2(1, 0);
			
		float anisotropy = abs((eigenvalues.y - eigenvalues.x) / (eigenvalues.x + eigenvalues.y));
		anisotropy *= anisotropy;
		anisotropy = saturate(anisotropy);
		anisotropy = max(anisotropy, 1e-15);
		anisotropyData.xyz = float3(t, anisotropy);
		anisotropyData.w = 1;
	}
			

	void KuwaharaPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float3 kuwahara : SV_TARGET0)
	{
		float sharpnessMultiplier = max(1023 * pow(( 2 * Sharpness / 3) + 0.333333, 4), 1e-10);
		float3 sum[6];
		float3 squaredSum[6];
		float gaussianSum[6];
		float sampleCount[6];

		float radius = length(float2((float(OILIFY_SIZE) / 2), (float(OILIFY_SIZE) / 4)));
		
		float3 anistropyData = tex2D(sAnisotropy, texcoord).xyz;
		float2 t = anistropyData.xy;
		float anisotropy = anistropyData.z;
		float tuning = exp2(Tuning - 1);
		float2x2 tuningMatrix = float2x2(tuning / (anisotropy + tuning), 0,
								0, (tuning + anisotropy) / tuning);
		float2x2 rotationMatrix = float2x2(t.x, -t.y, t.y, t.x);
		float2x2 offsetMatrix = mul(rotationMatrix, tuningMatrix);
		[unroll]
		for(int i = -(OILIFY_SIZE / 2); i < ((OILIFY_SIZE + 1) / 2); i++)
		{
			[unroll]
			for(int j = -(OILIFY_SIZE / 2); j < ((OILIFY_SIZE + 1) / 2); j++)
			{
				float2 offset = float2(i, j);
				if(abs(j) % 2 != 0)
				{
					offset.y -= 0.5;
				}
				
				if(all(int2(i, j) == 0))
				{
					[unroll]
					for(int k = 0; k < 6; k++)
					{
						float3 color = tex2D(sBackBuffer, texcoord).rgb * sharpnessMultiplier;
						sum[k] += color;
						squaredSum[k] += color * color;
						sampleCount[k]++;
					}
				}
				else if(length(offset) <= radius)
				{
					float angle = atan2(offset.x, offset.y) + PI;
					if(angle > 5.75958653158)
					{
						angle -= 2 * PI;
					}
					float sectorOffset = (float((angle * 6) / PI) + 1) / 2;
					int sector = floor(sectorOffset);
					sectorOffset -= float(sector);
					offset *= float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * Scale;
					offset = mul(offset, offsetMatrix);
					float3 color = tex2D(sBackBuffer, texcoord + offset).rgb * sharpnessMultiplier;
					sum[sector] += color;
					squaredSum[sector] += color * color;
					sampleCount[sector]++;
				}
			}
		}
		
		float3 weightedSum = 0;
		float3 weightSum = 0;
		[unroll]
		for(int i = 0; i < 6; i++)
		{
			float3 sumSquared = sum[i] * sum[i];
			float3 mean = sum[i] / sampleCount[i];
			float3 variance = (squaredSum[i] - ((sumSquared) / sampleCount[i]));
			variance /= sampleCount[0];
			float3 weight = 1 / (1 + pow(sqrt(max(dot(variance, float3(0.299, 0.587, 0.114)), 1e-5)), 8));
			weightedSum += mean * weight;
			weightSum += weight;
		}
		kuwahara = ((weightedSum) / weightSum) / sharpnessMultiplier;
#if GSHADE_DITHER
		kuwahara += TriDither(kuwahara, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
	}

	technique Oilify<ui_tooltip = "Oilify是各向异性kuwahara滤镜的修订版，用于创造一种绘画般的效果。\n\n"
							  "Part of Insane Shaders\n"
							  "By: Lord of Lunacy\n\n"
							  "OILIFY_SIZE: 改变过滤器使用的大小。\n"
							  "OILIFY_ITERATIONS: 从1到8的范围。";ui_label="油画";>
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = AnisotropyPS;
			RenderTarget0 = Anisotropy;
		}
		
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = KuwaharaPS;
		}
#if OILIFY_ITERATIONS > 1
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 2
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 3
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 4
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 5
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 6
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 7
	OILIFY_PASS
#endif	
	}
}
