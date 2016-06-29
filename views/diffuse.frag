#version 330
uniform sampler2D tex;
in vec2 texCoord;
in vec3 normal;

layout(location = 0) out vec4 out_frag_color;

void main()
{
	out_frag_color = vec4(texture(tex, texCoord).rgb * clamp(dot(normalize(vec3(1, 1, 1)), normal), 0.25, 1), texture(tex, texCoord).a);
}