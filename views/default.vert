#version 330
layout(location = 1) in vec3 in_position;
layout(location = 2) in vec2 in_tex;

uniform mat4 transform;
uniform mat4 projection;
out vec2 texCoord;

void main()
{
	gl_Position = vec4(in_position, 1);
	texCoord = in_tex;
}