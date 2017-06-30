#version 330
layout(location = 1) in vec3 in_position;
layout(location = 2) in vec2 in_tex;
layout(location = 3) in vec3 in_normal;

uniform mat4 normalmatrix;
uniform mat4 modelview;
uniform mat4 projection;
out vec2 texCoord;
out vec3 normal;
out vec3 vertexPos;
out vec3 viewNormal;

void main()
{
	vec4 worldPos = modelview * vec4(in_position, 1);
	gl_Position = projection * worldPos;
	texCoord = in_tex;
	viewNormal = mat3(modelview) * in_normal;
	normal = mat3(normalmatrix) * in_normal;
	vertexPos = worldPos.xyz;
}