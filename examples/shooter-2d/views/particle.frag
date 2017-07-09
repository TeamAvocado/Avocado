#version 330
in vec4 color;

layout(location = 0) out vec4 out_frag_color;

void main()
{
	out_frag_color = color * color.a;
}