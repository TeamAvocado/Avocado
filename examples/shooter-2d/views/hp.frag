#version 330
uniform float hp;
in vec2 texCoord;

layout(location = 0) out vec4 out_frag_color;

void main()
{
	if ((texCoord.x + 2) * 0.25 > hp)
		out_frag_color = vec4(1, 0, 0, 1);
	else
		out_frag_color = vec4(0, 1, 0, 1);
}