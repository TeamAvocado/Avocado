module avocado.gl3.gl3framebuffer;

import avocado.gl3;
import avocado.gl3.gltexture;
import avocado.gl3.gl3renderer;

import avocado.core.display.irenderer;
import avocado.core.display.irendertarget;

public import std.typecons : Flag, Yes, No;

struct FramebufferCreationInfo {
	TextureFilterMode minFilter = TextureFilterMode.Nearest;
	TextureFilterMode magFilter = TextureFilterMode.Nearest;
	int mode = GL_RGB;
	int inMode = 0;
	int type = GL_UNSIGNED_BYTE;

	void filter(TextureFilterMode val) @property {
		minFilter = val;
		magFilter = val;
	}
}

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

		assert(_textureInfos.length > 0 && _textureInfos.length < 16, "Must have between 1 and 15 framebuffers");

		foreach (i, info; _textureInfos) {
			auto color = new GLTexture();
			color.minFilter = info.minFilter;
			color.magFilter = info.magFilter;
			color.create(width, height, info.inMode == 0 ? info.mode : info.inMode, info.mode, null, info.type);
			_colors ~= color;
			_buffers ~= GL_COLOR_ATTACHMENT0 + cast(int)i;
		}

		if (_hasDepth) {
			_depth = new GLTexture();
			_depth.minFilter = _depthMinFilter;
			_depth.magFilter = _depthMagFilter;
			_depth.create(width, height, GL_DEPTH_COMPONENT24, GL_DEPTH_COMPONENT, null, GL_FLOAT);
		}

		glGenRenderbuffers(1, &_drb);
		glBindRenderbuffer(GL_RENDERBUFFER, _drb);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, width, height);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _drb);

		foreach (i, color; _colors)
			glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + cast(int)i, color.id, 0);
		if (_hasDepth)
			glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, _depth.id, 0);

		assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Framebuffer is not complete");
		enforceGLErrors();
	}

	void resize(uint width, uint height) {
		_width = width;
		_height = height;
		foreach (ref color; _colors)
			color.resize(width, height);
		if (_hasDepth && _depth)
			_depth.resize(width, height);
	}

	uint width() @property {
		return _width;
	}

	uint height() @property {
		return _height;
	}

	GLTexture[] color() @property {
		return _colors;
	}

	GLTexture depth() @property {
		return _depth;
	}

	void bind(IRenderer renderer) {
		assert(cast(GL3Renderer)renderer);
		glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
		glDrawBuffers(cast(int)_buffers.length, _buffers.ptr);
		glViewport(0, 0, _width, _height);
		(cast(GL3Renderer)renderer).clear();
	}

	ref FramebufferCreationInfo[] infos() @property {
		return _textureInfos;
	}

	ref TextureFilterMode depthMinFilter() @property {
		return _depthMinFilter;
	}

	ref TextureFilterMode depthMagFilter() @property {
		return _depthMagFilter;
	}

	void depthFilter(TextureFilterMode mode) @property {
		_depthMinFilter = _depthMagFilter = mode;
	}

private:

	const(uint)[] _buffers;
	TextureFilterMode _depthMinFilter, _depthMagFilter;
	FramebufferCreationInfo[] _textureInfos = [FramebufferCreationInfo.init];
	uint _width, _height;
	uint _fbo, _drb;
	bool _hasDepth;
	GLTexture[] _colors;
	GLTexture _depth;
}
