#version 330
layout(location = 0) in vec2 in_position;
layout(location = 1) in vec2 in_partpos;
layout(location = 2) in vec4 in_color;

uniform mat4 modelview;
uniform mat4 projection;
out vec4 color;

void main()
{
	gl_Position = projection * modelview * vec4(in_position + in_partpos, 0, 1);
	color = in_color;
}