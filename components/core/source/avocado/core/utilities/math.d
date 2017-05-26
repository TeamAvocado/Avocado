module avocado.core.utilities.math;

public import gl3n.linalg;
public import gl3n.math;

quat lookAt(vec3 source, vec3 dest, vec3 up)
in {
	assert(abs(source.length_squared - 1.0f) < 0.00001f, "Source must be normalized");
	assert(abs(dest.length_squared - 1.0f) < 0.00001f, "Dest must be normalized");
	assert(abs(up.length_squared - 1.0f) < 0.00001f, "Up must be normalized");
}
out (res) {
	assert(res.isFinite, "Invalid quaternion " ~ (cast()res).toString);
}
body {
	float d = dot(source, dest);
	if (abs(d + 1.0f) < 0.0001f) // d == -1
		return quat(cradians!180, up);
	if (abs(d - 1.0f) < 0.0001f) // d == 1
		return quat.identity;
	return quat(acos(d), cross(source, dest).normalized);
}

/// Helper calling atan2(source.y - dest.y, source.x - dest.x)
/// 0 = facing towards the X axis
float lookAt(vec2 source, vec2 dest) {
	return atan2(source.y - dest.y, source.x - dest.x);
}

float cos_lerp(T)(T a, T b, float t) {
	t = (1 - cos(t * 3.1415926f)) * 0.5f;
	return a * (1 - t) + b * t;
}

unittest {
	assert(abs(cos_lerp(0, 1, 0) - 0) < 0.00001f);
	assert(abs(cos_lerp(0, 1, 1) - 1) < 0.00001f);
	assert(abs(cos_lerp(0, 1, 0.5f) - 0.5f) < 0.00001f);
}
