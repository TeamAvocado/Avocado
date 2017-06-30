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

	static GLTexture createCubemap(in Bitmap posX, in Bitmap negX, in Bitmap posY, in Bitmap negY,
			in Bitmap posZ, in Bitmap negZ) {
		GLTexture ret = new GLTexture(GL_TEXTURE_CUBE_MAP);
		assert(posX.width == negX.width && negX.width == posY.width && posY.width == negY.width
				&& negY.width == posZ.width && posZ.width == negZ.width);
		assert(posX.height == negX.height && negX.height == posY.height && posY.height == negY.height
				&& negY.height == posZ.height && posZ.height == negZ.height);
		assert(posX.width == posX.height);
		auto px = fixBitmap(posX, "cubemap+x", posX.width);
		auto nx = fixBitmap(negX, "cubemap-x", posX.width);
		auto py = fixBitmap(posY, "cubemap+y", posX.width);
		auto ny = fixBitmap(negY, "cubemap-y", posX.width);
		auto pz = fixBitmap(posZ, "cubemap+z", posX.width);
		auto nz = fixBitmap(negZ, "cubemap-z", posX.width);

		ret.wrapX = TextureClampMode.ClampToEdge;
		ret.wrapY = TextureClampMode.ClampToEdge;
		ret.wrapZ = TextureClampMode.ClampToEdge;

		glGenTextures(1, &ret._id);
		glBindTexture(GL_TEXTURE_CUBE_MAP, ret._id);

		glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA,
				posX.width, posX.width, 0, GL_RGBA, GL_UNSIGNED_BYTE, px.pixels.ptr);
		glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA,
				posX.width, posX.width, 0, GL_RGBA, GL_UNSIGNED_BYTE, nx.pixels.ptr);
		glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA,
				posX.width, posX.width, 0, GL_RGBA, GL_UNSIGNED_BYTE, py.pixels.ptr);
		glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA,
				posX.width, posX.width, 0, GL_RGBA, GL_UNSIGNED_BYTE, ny.pixels.ptr);
		glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA,
				posX.width, posX.width, 0, GL_RGBA, GL_UNSIGNED_BYTE, pz.pixels.ptr);
		glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA,
				posX.width, posX.width, 0, GL_RGBA, GL_UNSIGNED_BYTE, nz.pixels.ptr);

		ret.applyParameters();

		ret._inMode = GL_RGBA;
		ret._mode = GL_RGBA;
		ret._type = GL_UNSIGNED_BYTE;
		ret._width = posX.width;
		ret._height = posX.width;

		return ret;
	}

	this(int target = GL_TEXTURE_2D) {
		_target = target;
	}

	~this() {
		glDeleteTextures(1, &_id);
	}

	void create(int width, int height, in void[] pixels) {
		create(width, height, GL_RGBA, pixels);
	}

	void create(int width, int height, int mode, in void[] pixels) {
		create(width, height, mode, mode, pixels, GL_UNSIGNED_BYTE);
	}

	void create(int width, int height, int inMode, int mode, in void[] pixels, int type = GL_UNSIGNED_BYTE) {
		glGenTextures(1, &_id);
		glBindTexture(_target, _id);

		glTexImage2D(_target, 0, inMode, width, height, 0, mode, type, pixels.ptr);

		applyParameters();

		_inMode = inMode;
		_mode = mode;
		_type = type;
		_width = width;
		_height = height;
	}

	void applyParameters() {
		bind(null, 0);

		glTexParameteri(_target, GL_TEXTURE_MAG_FILTER, _magFilter);
		glTexParameteri(_target, GL_TEXTURE_MIN_FILTER, _minFilter);

		glTexParameteri(_target, GL_TEXTURE_WRAP_S, _wrapX);
		glTexParameteri(_target, GL_TEXTURE_WRAP_T, _wrapY);
		glTexParameteri(_target, GL_TEXTURE_WRAP_R, _wrapZ);

		if (_enableMipMaps) {
			glGenerateMipmap(_target);
			glTexParameteri(_target, GL_TEXTURE_MAX_ANISOTROPY_EXT, 16);
		}
	}

	void bind(IRenderer renderer, int unit) {
		glActiveTexture(GL_TEXTURE0 + unit);
		glBindTexture(_target, _id);
	}

	void fromBitmap(in Bitmap bitmap, in string name = "Bitmap") {
		auto fixed = fixBitmap(bitmap, name);
		int mode = GL_RGBA;

		create(fixed.width, fixed.height, mode, fixed.pixels);
	}

	void resize(int width, int height, in void[] pixels = null) {
		bind(null, 0);
		glTexImage2D(_target, 0, _inMode, width, height, 0, _mode, _type, pixels.ptr);
		_width = width;
		_height = height;
	}

	Bitmap toBitmap() {
		bind(null, 0);
		ubyte[] pixels = new ubyte[width * height];
		glGetTexImage(_target, 0, GL_BGRA, GL_UNSIGNED_BYTE, pixels.ptr);
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

	ref auto wrapZ() @property {
		return _wrapZ;
	}

private:
	bool _enableMipMaps = false;

	TextureFilterMode _minFilter = TextureFilterMode.Linear;
	TextureFilterMode _magFilter = TextureFilterMode.Linear;

	TextureClampMode _wrapX = TextureClampMode.Repeat;
	TextureClampMode _wrapY = TextureClampMode.Repeat;
	TextureClampMode _wrapZ = TextureClampMode.Repeat;

	int _inMode, _mode;
	int _type;
	uint _id;
	int _width, _height;
	int _target;
}

Bitmap fixBitmap(in Bitmap bitmap, string name, int errSize = 4) {
	if (bitmap.width == 0 || bitmap.height == 0 || bitmap.pixels.length != bitmap.width * bitmap.height * 4) {
		debug {
			assert(0, "Invalid bitmap '" ~ name ~ "'");
		} else {
			ubyte[] errDat = new ubyte[errSize * errSize * 4];
			for (int i = 0; i < errSize * errSize; i++) {
				int x = i % errSize;
				int y = i / errSize;
				bool pink = ((x & 1) && !(y & 1)) || (!(x & 1) && (y & 1));
				errDat[i * 4 + 0] = pink ? 255 : 0;
				errDat[i * 4 + 1] = 0;
				errDat[i * 4 + 2] = pink ? 255 : 0;
				errDat[i * 4 + 3] = 255;
			}
			return Bitmap(errSize, errSize, errDat);
		}
	} else
		return bitmap;
}
