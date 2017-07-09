#version 330
layout(location = 0) in vec2 in_position;

uniform mat4 modelview;
uniform mat4 projection;
out vec2 texCoord;

void main()
{
	gl_Position = projection * modelview * vec4(in_position, 0, 1);
	texCoord = in_position;
}