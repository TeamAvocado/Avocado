module avocado.core.utilities.projection;

import avocado.core.util;

/// Creates a perspective projection matrix
mat4 perspective(float width, float height, float fov, float near, float far) {
	return mat4.perspective(width, height, fov, near, far);
}

/// Creates an orthographic projection matrix with top left as origin and bottom right using width and height
mat4 ortho2D(float width, float height, float near, float far) {
	return mat4.orthographic(0, width, height, 0, near, far);
}

/// Creates a 3D orthographic projection matrix with centered origin
mat4 ortho3D(float aspect, float near, float far, float scale) {
	return mat4.orthographic(-aspect, aspect, -1, 1, near, far).scale(scale, scale, scale);
}
