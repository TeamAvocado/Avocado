#version 330
layout(location = 0) in vec2 in_position;
layout(location = 1) in vec4 in_charRect;
layout(location = 2) in vec2 in_charPos;

uniform mat4 modelview;
uniform mat4 projection;
out vec2 texCoord;

void main()
{
	gl_Position = projection * modelview * vec4(in_position * in_charRect.zw + in_charPos, 0, 1);
	texCoord = in_position * in_charRect.zw + in_charRect.xy;
}