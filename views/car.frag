#version 330
uniform sampler2D tex;
uniform samplerCube skybox;
uniform vec3 eyeWorldPos;
in vec3 vertexPos;
in vec2 texCoord;
in vec3 normal;
in vec3 viewNormal;

layout(location = 0) out vec4 out_frag_color;

void main()
{
	vec3 eye = normalize(eyeWorldPos - vertexPos);
	vec3 nrm = normalize(normal);
	vec3 lightDir = normalize(vec3(-0.5, 0.5, -0.3));
	vec3 lightReflect = -normalize(reflect(lightDir, nrm));

	float specIntensity = 32;

	float df = max(0, dot(nrm, lightDir));
	float sf = max(0, dot(eye, lightReflect));
	sf = pow(sf, specIntensity);

	vec3 ambient = texture(skybox, lightReflect).xyz;

	float fresnel = dot(vec3(0, 0, 1), viewNormal);
	float clearcoat = pow(fresnel, 0.9);

	vec3 col = texture(tex, texCoord).rgb * df + vec3(0.01) * sf;

	col = col * clearcoat + ambient * (1 - clearcoat);

	out_frag_color = vec4(col, texture(tex, texCoord).a);
}