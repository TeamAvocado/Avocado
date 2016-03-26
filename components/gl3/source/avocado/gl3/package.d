module avocado.gl3;

public:

void enforceGLErrors(int line = __LINE__, string file = __FILE__)(string msg = "", bool throwException = true) {
	import std.format : format;

	GLenum err = GL_NO_ERROR;
	while ((err = glGetError()) != GL_NO_ERROR) {
		string errmsg = "";
		switch (err) {
		case GL_INVALID_ENUM:
			errmsg = " - GL_INVALID_ENUM\nAn unacceptable value is specified for an enumerated argument. The offending command is ignored and has no other side effect than to set the error flag.";
			break;
		case GL_INVALID_VALUE:
			errmsg = " - GL_INVALID_VALUE\nA numeric argument is out of range. The offending command is ignored and has no other side effect than to set the error flag.";
			break;
		case GL_INVALID_OPERATION:
			errmsg = " - GL_INVALID_OPERATION\nThe specified operation is not allowed in the current state. The offending command is ignored and has no other side effect than to set the error flag.";
			break;
		case GL_INVALID_FRAMEBUFFER_OPERATION:
			errmsg = " - GL_INVALID_FRAMEBUFFER_OPERATION\nThe framebuffer object is not complete. The offending command is ignored and has no other side effect than to set the error flag.";
			break;
		case GL_OUT_OF_MEMORY:
			errmsg = " - GL_OUT_OF_MEMORY\nThere is not enough memory left to execute the command. The state of the GL is undefined, except for the state of the error flags, after this error is recorded.";
			break;
		// case GL_STACK_UNDERFLOW:
		// 	errmsg = " - GL_STACK_UNDERFLOW\nAn attempt has been made to perform an operation that would cause an internal stack to underflow.";
		// 	break;
		// case GL_STACK_OVERFLOW:
		// 	errmsg = " - GL_STACK_OVERFLOW\nAn attempt has been made to perform an operation that would cause an internal stack to overflow.";
		// 	break;
		default:
			break;
		}
		if (throwException)
			throw new Exception(msg ~ format("OpenGL error code: %d (0x0%x)%s", err, err, errmsg), file, line);
		else
			std.stdio.writefln("%s%s:%s OpenGL error code: %d (0x0%x)%s", msg, file, line, err, err, errmsg);
	}
}

import derelict.opengl3.gl3;
import avocado.gl3.gl3renderer;
import avocado.gl3.gl3mesh;
import avocado.gl3.gl3shader;
import avocado.gl3.gl3framebuffer;
import avocado.gl3.gltexture;
