module avocado.gl3.gl3framebuffer;

import avocado.gl3;
import avocado.gl3.gltexture;
import avocado.gl3.gl3renderer;

import avocado.core.display.irenderer;
import avocado.core.display.irendertarget;

public import std.typecons : Flag, Yes, No;

/// render target using framebuffer objects
class GL3Framebuffer : IRenderTarget {
public:
	this(Flag!"depth" hasDepth = Yes.depth) {
		_hasDepth = hasDepth;
	}

	void create(uint width, uint height) {
		_width = width;
		_height = height;

		glGenFramebuffers(1, &_fbo);
		glBindFramebuffer(GL_FRAMEBUFFER, _fbo);

		_color = new GLTexture();
		_color.minFilter = TextureFilterMode.Nearest;
		_color.magFilter = TextureFilterMode.Nearest;
		_color.create(width, height, GL_RGB, null);

		if (_hasDepth) {
			_depth = new GLTexture();
			_depth.minFilter = TextureFilterMode.Nearest;
			_depth.magFilter = TextureFilterMode.Nearest;
			_depth.create(width, height, GL_RGB, null);
		}

		glGenRenderbuffers(1, &_drb);
		glBindRenderbuffer(GL_RENDERBUFFER, _drb);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, width, height);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _drb);

		glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, _color.id, 0);
		if (_hasDepth)
			glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, _depth.id, 0);

		if (_hasDepth)
			glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT].ptr);
		else
			glDrawBuffers(1, [GL_COLOR_ATTACHMENT0].ptr);

		assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Framebuffer is not complete");
	}

	void resize(uint width, uint height) {
		_width = width;
		_height = height;
		_color.resize(width, height);
		if (_hasDepth && _depth)
			_depth.resize(width, height);
	}

	GLTexture color() @property {
		return _color;
	}

	GLTexture depth() @property {
		return _depth;
	}

	void bind(IRenderer renderer) {
		assert(cast(GL3Renderer)renderer);
		glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
		glViewport(0, 0, _width, _height);
		(cast(GL3Renderer)renderer).clear();
	}

private:

	uint _width, _height;
	uint _fbo, _drb;
	bool _hasDepth;
	GLTexture _color, _depth;
}
