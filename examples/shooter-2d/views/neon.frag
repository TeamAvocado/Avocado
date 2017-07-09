#version 330
uniform sampler2D blurred;
uniform sampler2D original;
in vec2 texCoord;

layout(location = 0) out vec4 out_frag_color;

void main()
{
	vec4 color = texture(original, texCoord);
	vec4 blur = texture(blurred, texCoord);
	out_frag_color = blur * 1.5 + vec4(vec3(color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722) * 1.2, 0);
}