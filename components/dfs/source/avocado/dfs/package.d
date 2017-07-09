module avocado.dfs;

import avocado.core.resource.resourceprovider;

import archive.tar;
import archive.targz;
import archive.zip;

import std.algorithm;
import std.stdio;
import std.string;
import std.path;
import fs = std.file;

private enum DirType {
	folder,
	zip,
	targz,
	tar
}

private struct VirtualDirectory {
	DirType type;
	string path;
	union {
		ZipArchive zip;
		TarGzArchive targz;
		TarArchive tar;
	}
}

/// Resource manager using std.file and archive. When a different name is required use `import avocado.dfs : DfsResourceManager = ResourceManager;`
/// This also works with file archives.
class ResourceManager : IResourceManager {
	this() {
		loaded = new SimpleResourceProviderManager();
	}

	~this() {
		unload();
	}

	/// Appends search paths. Last element in the arguments list will be last.
	void append(string[] paths...) {
		foreach (path; paths)
			appendOne(path);
	}

	/// Appends multiple search paths based on file.dirEntries
	void appendAll(string path, string filter) {
		if (fs.exists(path)) {
			auto packs = fs.dirEntries(path, filter, fs.SpanMode.shallow, false);
			foreach (pack; packs)
				appendOne(pack);
		}
	}

	/// Prepends search paths. First element in the arguments list will be first.
	void prepend(string[] paths...) {
		foreach (path; paths)
			prependOne(path);
	}

	/// Prepends multiple search paths based on file.dirEntries
	void prependAll(string path, string filter) {
		if (fs.exists(path)) {
			auto packs = fs.dirEntries(path, filter, fs.SpanMode.shallow, false);
			foreach (pack; packs)
				prependOne(pack);
		}
	}

	///
	void removeSearchPath(string path) {
		this.paths = this.paths.remove!(a => a.path == path);
	}

	///
	void clearSearchPaths() {
		this.paths.length = 0;
	}

	/// Returns the location of a file. Returns null if not found.
	string findFile(string resource) {
		assert(!resource.isAbsolute, "Absolute resource locations are not allowed!");
		foreach (path; paths) {
			if (path.type == DirType.folder) {
				string p = buildPath(path.path, resource);
				if (fs.exists(p))
					return p;
			}
		}
		return null;
	}

	/// Returns true if the resource exists in any search path
	bool fileExists(string resource) {
		assert(!resource.isAbsolute, "Absolute resource locations are not allowed!");
		foreach (path; paths) {
			final switch (path.type) with (DirType) {
			case folder:
				string p = buildPath(path.path, resource);
				if (fs.exists(p))
					return true;
				break;
			case tar:
				const file = path.tar.getFile(resource);
				if (file !is null)
					return true;
				break;
			case targz:
				const file = path.targz.getFile(resource);
				if (file !is null)
					return true;
				break;
			case zip:
				const file = path.zip.getFile(resource);
				if (file !is null)
					return true;
				break;
			}
		}
		return false;
	}

	/// Lists all resource names in a directory.
	string[] listResources(string directory, bool includeSubDirectories = false) {
		assert(!directory.isAbsolute, "Absolute resource locations are not allowed!");
		if (!directory.length || directory[$ - 1] != '/')
			directory ~= '/';
		string[] ret;
		foreach (path; paths) {
			final switch (path.type) with (DirType) {
			case folder:
				string p = buildPath(path.path, directory);
				auto dirLen = path.path.length;
				if (dirLen && path.path[$ - 1] != '/')
					dirLen++;
				if (fs.exists(p))
					foreach (f; fs.dirEntries(p, includeSubDirectories ? fs.SpanMode.breadth : fs.SpanMode.shallow))
						if (f.isFile)
							ret ~= f[dirLen .. $];
				break;
			case tar:
				auto dir = path.tar.getDirectory(directory);
				if (dir !is null)
					foreach (file; dir.files)
						if (includeSubDirectories || file.path.startsWith(directory))
							ret ~= file.path;
				break;
			case targz:
				auto dir = path.targz.getDirectory(directory);
				if (dir !is null)
					foreach (file; dir.files)
						if (includeSubDirectories || file.path.startsWith(directory))
							ret ~= file.path;
				break;
			case zip:
				auto dir = path.zip.getDirectory(directory);
				if (dir !is null)
					foreach (file; dir.files)
						if (includeSubDirectories || file.path.startsWith(directory))
							ret ~= file.path;
				break;
			}
		}
		return ret;
	}

	immutable(ubyte)[] readFile(string resource) {
		assert(!resource.isAbsolute, "Absolute resource locations are not allowed!");
		foreach (path; paths) {
			final switch (path.type) with (DirType) {
			case folder:
				string p = buildPath(path.path, resource);
				if (fs.exists(p))
					return cast(immutable(ubyte)[])fs.read(p);
				break;
			case tar:
				auto file = path.tar.getFile(resource);
				if (file !is null)
					return file.data;
				break;
			case targz:
				auto file = path.targz.getFile(resource);
				if (file !is null)
					return file.data;
				break;
			case zip:
				auto file = path.zip.getFile(resource);
				if (file !is null)
					return file.data;
				break;
			}
		}
		throw new InvalidFileException("Resource '" ~ resource ~ "' not found");
	}

	/// Reads raw data from a resource for manual creation.
	bool read(string resource, ref ubyte[] ret) {
		assert(!resource.isAbsolute, "Absolute resource locations are not allowed!");
		if (!fileExists(resource))
			return false;
		ret = readFile(resource).dup;
		return true;
	}

	/// Loads a resource using a ResourceProvider and references it for unloading
	T load(T : IResourceProvider, Args...)(string resource, Args constructArgs) {
		scope (failure)
			writeln("Error while loading ", resource);
		ubyte[] data;
		if (!read(resource, data)) {
			debug {
				assert(0, "Resource not found: " ~ resource);
			} else {
				T res = new T(constructArgs);
				res.error();
				return res;
			}
		}
		auto ret = loadResource!T(data, constructArgs);
		loaded.reference(ret);
		return ret;
	}
	/// Unloads all resources
	void unload() {
		loaded.destroy();
	}

private:
	void prependOne(string path) {
		paths = path.getVDir ~ paths;
	}

	void appendOne(string path) {
		paths ~= path.getVDir;
	}

	VirtualDirectory[] paths;
	SimpleResourceProviderManager loaded;
}

class InvalidFileException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) pure nothrow @nogc @safe {
		super(msg, file, line);
	}
}

VirtualDirectory getVDir(ref in string path) {
	import std.stdio : File;

	VirtualDirectory dir;

	if (!fs.exists(path))
		throw new InvalidFileException("File/Folder '" ~ path ~ "' does not exist!");

	dir.path = path;
	if (fs.isDir(path)) {
		dir.type = DirType.folder;
	} else {
		const ext = path.extension;
		if (ext == ".zip")
			dir.type = DirType.zip;
		else if (ext == ".tar")
			dir.type = DirType.tar;
		else if (ext == ".gz")
			dir.type = DirType.targz;
		else {
			auto file = File(path, "rb");
			ubyte[] buf = new ubyte[270];
			buf = file.rawRead(buf);
			if (buf.length >= 4 && buf[0 .. 4] == [0x50, 0x4b, 0x03, 0x04])
				dir.type = DirType.zip;
			else if (buf.length >= 262 && buf[257 .. 262] == cast(ubyte[5])"ustar")
				dir.type = DirType.tar;
			else
				dir.type = DirType.targz;
		}
	}

	if (dir.type == DirType.zip)
		dir.zip = new ZipArchive(fs.read(path));
	else if (dir.type == DirType.tar)
		dir.tar = new TarArchive(fs.read(path));
	else if (dir.type == DirType.targz)
		dir.targz = new TarGzArchive(fs.read(path));

	return dir;
}
