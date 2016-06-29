#version 330
layout(location = 1) in vec3 in_position;
layout(location = 2) in vec2 in_tex;
layout(location = 3) in vec3 in_normal;
layout(location = 4) in ivec4 in_boneids;
layout(location = 5) in vec4 in_weights;

#define MAX_BONES 100

uniform mat4 modelview;
uniform mat4 projection;
uniform mat4 bones[MAX_BONES];
out vec2 texCoord;
out vec3 normal;

void main()
{
	mat4 boneTransform;
	boneTransform += bones[in_boneids[0]] * in_weights[0];
	boneTransform += bones[in_boneids[1]] * in_weights[1];
	boneTransform += bones[in_boneids[2]] * in_weights[2];
	boneTransform += bones[in_boneids[3]] * in_weights[3];
	mat4 bmvp = projection * modelview * boneTransform;
	gl_Position = bmvp * vec4(in_position, 1);
	texCoord = in_tex;
	normal = in_normal;
}
