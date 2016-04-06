module avocado.gl3.gltexture;

import avocado.core.resource.resourceprovider;
import avocado.core.display.itexture;
import avocado.core.display.irenderer;
import avocado.core.display.bitmap;
import avocado.gl3;

enum TextureFilterMode : int {
	Linear = GL_LINEAR,
	Nearest = GL_NEAREST,
	NearestMipmapNearest = GL_NEAREST_MIPMAP_NEAREST,
	LinearMipmapNearest = GL_LINEAR_MIPMAP_NEAREST,
	NearestMipmapLinear = GL_NEAREST_MIPMAP_LINEAR,
	LinearMipmapLinear = GL_LINEAR_MIPMAP_LINEAR,
}

enum TextureClampMode : int {
	ClampToBorder = GL_CLAMP_TO_BORDER,
	ClampToEdge = GL_CLAMP_TO_EDGE,
	Repeat = GL_REPEAT,
	Mirror = GL_MIRRORED_REPEAT
}

class GLTexture : ITexture, IResourceProvider {
public:
	@property int id() {
		return _id;
	}

	@property int width() {
		return _width;
	}

	@property int height() {
		return _height;
	}

	this() {
	}

	~this() {
		glDeleteTextures(1, &_id);
	}

	void create(int width, int height, in void[] pixels) {
		create(width, height, GL_RGBA, pixels);
	}

	void create(int width, int height, int mode, in void[] pixels) {
		glGenTextures(1, &_id);
		glBindTexture(GL_TEXTURE_2D, _id);

		glTexImage2D(GL_TEXTURE_2D, 0, mode, width, height, 0, mode, GL_UNSIGNED_BYTE, pixels.ptr);

		applyParameters();

		_inMode = mode;
		_mode = mode;
		_width = width;
		_height = height;
		_type = GL_UNSIGNED_BYTE;
	}

	void create(int width, int height, int inMode, int mode, in void[] pixels, int type = GL_UNSIGNED_BYTE) {
		glGenTextures(1, &_id);
		glBindTexture(GL_TEXTURE_2D, _id);

		glTexImage2D(GL_TEXTURE_2D, 0, inMode, width, height, 0, mode, type, pixels.ptr);

		applyParameters();

		_inMode = inMode;
		_mode = mode;
		_type = type;
		_width = width;
		_height = height;
	}

	void applyParameters() {
		bind(null, 0);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _magFilter);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _minFilter);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _wrapX);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _wrapY);

		if (_enableMipMaps) {
			glGenerateMipmap(GL_TEXTURE_2D);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 16);
		}
	}

	void bind(IRenderer renderer, int unit) {
		glActiveTexture(GL_TEXTURE0 + unit);
		glBindTexture(GL_TEXTURE_2D, _id);
	}

	void fromBitmap(in Bitmap bitmap, in string name = "Bitmap") {

		if (bitmap.width == 0 || bitmap.height == 0 || bitmap.pixels.length != bitmap.width * bitmap.height * 4) {
			debug {
				assert(0, "Invalid bitmap '" ~ name ~ "'");
			} else {
				enum ERR_SIZE = 1 << 2;
				ubyte[ERR_SIZE * ERR_SIZE * 4] errDat;
				for (int i = 0; i < ERR_SIZE * ERR_SIZE; i++) {
					int x = i % ERR_SIZE;
					int y = i / ERR_SIZE;
					bool pink = ((x & 1) && !(y & 1)) || (!(x & 1) && (y & 1));
					errDat[i * 4 + 0] = pink ? 255 : 0;
					errDat[i * 4 + 1] = 0;
					errDat[i * 4 + 2] = pink ? 255 : 0;
					errDat[i * 4 + 3] = 255;
				}
				create(ERR_SIZE, ERR_SIZE, GL_RGBA, errDat);
				return;
			}
		}

		int mode = GL_RGBA;

		create(bitmap.width, bitmap.height, mode, bitmap.pixels);
	}

	void resize(int width, int height, in void[] pixels = null) {
		bind(null, 0);
		glTexImage2D(GL_TEXTURE_2D, 0, _inMode, width, height, 0, _mode, _type, pixels.ptr);
		_width = width;
		_height = height;
	}

	Bitmap toBitmap() {
		bind(null, 0);
		ubyte[] pixels = new ubyte[width * height];
		glGetTexImage(GL_TEXTURE_2D, 0, GL_BGRA, GL_UNSIGNED_BYTE, pixels.ptr);
		scope (exit)
			pixels.length = 0;
		return Bitmap(cast(int)width, cast(int)height, pixels.dup);
	}

	/// Unused
	void error() {
	}

	/// Unused
	@property string errorInfo() {
		return "";
	}

	/// Loads a texture from a memory stream
	bool load(ref ubyte[] stream) {
		fromBitmap(Bitmap.fromMemory(stream));
		return true;
	}

	/// True for .png, .bmp, .jpg and .tga
	bool canRead(string extension) {
		switch (extension) {
		case "png":
		case "jpg":
		case "jpeg":
		case "bmp":
		case "tga":
			return true;
		default:
			return false;
		}
	}

	ref auto minFilter() @property {
		return _minFilter;
	}

	ref auto magFilter() @property {
		return _magFilter;
	}

	ref auto wrapX() @property {
		return _wrapX;
	}

	ref auto wrapY() @property {
		return _wrapY;
	}

private:
	bool _enableMipMaps = false;

	TextureFilterMode _minFilter = TextureFilterMode.Linear;
	TextureFilterMode _magFilter = TextureFilterMode.Linear;

	TextureClampMode _wrapX = TextureClampMode.Repeat;
	TextureClampMode _wrapY = TextureClampMode.Repeat;

	int _inMode, _mode;
	int _type;
	uint _id;
	int _width, _height;
}
