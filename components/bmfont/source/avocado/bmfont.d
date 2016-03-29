module avocado.bmfont;

import bmfont;

import avocado.core;

import std.path;

/// Class for loading BMFont files and the associated textures from a resource
class BMFont(Texture : ITexture, Resource : IResourceManager) : IResourceProvider {
public:
	this(Resource res, string basePath) {
		_res = res;
		_basePath = basePath;
	}

	/// Contains the font information
	Font value;
	Texture[] pages;

	/// Unused
	void error() {
	}

	/// Unused
	@property string errorInfo() {
		return exception.toString();
	}

	/// Loads a resource from a memory stream
	bool load(ref ubyte[] stream) {
		try {
			value = parseFnt(stream);
			foreach (page; value.pages)
				pages ~= _res.load!Texture(buildPath(_basePath, page));
			return true;
		}
		catch (Exception e) {
			exception = e;
			return false;
		}
	}

	/// True for .fnt
	bool canRead(string extension) {
		return extension == "fnt";
	}

	/// Can cast to a bmfont.Font
	T opCast(T)() if (is(T == Font)) {
		return cast(T)value;
	}

private:
	string _basePath;
	Resource _res;
	Throwable exception;
}
