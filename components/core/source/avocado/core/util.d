module avocado.core.util;

public:

import gl3n.aabb;
import gl3n.frustum;
import gl3n.interpolate;
import gl3n.linalg;
import gl3n.math;
import gl3n.plane;
import gl3n.util;
import gl3n.ext.hsv;
import gl3n.ext.matrixstack;

import avocado.core.utilities.projection;
import avocado.core.utilities.math;

mixin template BasicComponent(string name, T) {
	import std.string;

	mixin(`final struct ` ~ name ~ ` {
		T value;
		alias value this;
		mixin ComponentBase;

		string toString() const {
			return name ~ ": " ~ value.to!string;
		}
	}`);
}
