#version 330
uniform sampler2D tex;
uniform int width;

#define BLUR_AMOUNT 4
uniform float kernel[BLUR_AMOUNT * 2 + 1];

in vec2 texCoord;

layout(location = 0) out vec4 out_frag_color;

void main()
{
	float step = 1.0f / width;
	vec4 color = vec4(0, 0, 0, 0);
	for(int i = -BLUR_AMOUNT; i <= BLUR_AMOUNT; i++)
	{
		color += texture(tex, texCoord + vec2(0, i * step)) * kernel[i + BLUR_AMOUNT];
	}
	out_frag_color = color;
}