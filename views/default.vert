#version 330
layout(location = 1) in vec3 in_position;
layout(location = 2) in vec2 in_tex;
layout(location = 3) in vec3 in_normal;

uniform mat4 modelview;
uniform mat4 projection;
out vec2 texCoord;
out vec3 normal;

void main()
{
	gl_Position = projection * modelview * vec4(in_position, 1);
	texCoord = in_tex;
	normal = in_normal;
}