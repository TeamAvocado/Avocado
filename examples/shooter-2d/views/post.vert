#version 330
layout(location = 0) in vec2 in_position;

out vec2 texCoord;

void main()
{
	gl_Position = vec4((in_position - vec2(0.5, 0.5)) * 2, 0, 1);
	texCoord = in_position;
}