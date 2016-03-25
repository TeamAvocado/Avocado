module avocado.gl3;

public:

void enforceGLErrors() {
	import std.format : format;

	GLenum err = GL_NO_ERROR;
	while ((err = glGetError()) != GL_NO_ERROR) {
		throw new Exception(format("OpenGL error code: %d (0x0%x)", err, err));
	}
}

import derelict.opengl3.gl3;
import avocado.gl3.gl3renderer;
import avocado.gl3.gl3mesh;
import avocado.gl3.gl3shader;
import avocado.gl3.gl3framebuffer;
import avocado.gl3.gltexture;
