module avocado.physfs.resourcemanager;

import avocado.core.resource.resourceprovider;

import derelict.physfs.physfs;

import std.string;
import std.path;
import fs = std.file;

/// Resource manager using physfs. When a different name is required use `import avocado.physfs.resourcemanager : PhysfsResourceManager = ResourceManager;`
/// This also works with file archives.
class ResourceManager : IResourceManager {
    /// Loads the physfs library. There can only be one instance of this class!
    this(string argv0 = null) {
        DerelictPHYSFS.load();
        assert(!PHYSFS_isInit(), "Can only have one physfs ResourceManager instance!");
        loaded = new SimpleResourceProviderManager();
        auto result = PHYSFS_init(argv0.toStringz());
        assert(result, fromStringz(PHYSFS_getLastError()));
    }

    ~this() {
        unload();
        auto result = PHYSFS_deinit();
        assert(result, fromStringz(PHYSFS_getLastError()));
    }
    /// Appends search paths. Last element in the arguments list will be last.
    void append(string[] paths...) {
        foreach (p; paths) {
            auto result = PHYSFS_mount(p.toStringz(), null, 1);
            assert(result, "Path " ~ p ~ ": " ~ fromStringz(PHYSFS_getLastError()));
        }
    }
    /// Appends multiple search paths based on file.dirEntries
    void appendAll(string path, string filter) {
        if (fs.exists(path)) {
            auto packs = fs.dirEntries(path, filter, fs.SpanMode.shallow, false);
            foreach (pack; packs)
                append(pack);
        }
    }
    /// Prepends search paths. First element in the arguments list will be first.
    void prepend(string[] paths...) {
        foreach_reverse (p; paths) {
            auto result = PHYSFS_mount(p.toStringz(), null, 0);
            assert(result, "Path " ~ p ~ ": " ~ fromStringz(PHYSFS_getLastError()));
        }
    }
    /// Prepends multiple search paths based on file.dirEntries
    void prependAll(string path, string filter) {
        if (fs.exists(path)) {
            auto packs = fs.dirEntries(path, filter, fs.SpanMode.shallow, false);
            foreach (pack; packs)
                prepend(pack);
        }
    }
    ///
    void removeSearchPath(string path) {
        auto result = PHYSFS_removeFromSearchPath(path.toStringz());
        assert(result, fromStringz(PHYSFS_getLastError()));
    }
    ///
    void clearSearchPaths() {
        for (char** path = PHYSFS_getSearchPath(); *path !is null; path++) {
            removeSearchPath(fromStringz(*path).idup);
        }
    }
    /// Returns the location of a file. Returns null if not found.
    string findFile(string resource) {
        string dir = PHYSFS_getRealDir(resource.toStringz()).fromStringz().idup;
        if (!dir)
            return null;
        return (cast(string) buildPath(dir, resource)).idup;
    }
    /// Loads a resource using a ResourceProvider and references it for unloading
    T load(T : IResourceProvider)(string resource) {
        auto resourcez = resource.toStringz();
        if (!PHYSFS_exists(resourcez)) {
            debug assert(0, "Resource not found: " ~ resource);
        else {
                T res = new T();
                res.error();
                return res;
            }
        }
        PHYSFS_File* file = PHYSFS_openRead(resourcez);
        if (!file) {
            debug assert(0,
                "Error opening resource '" ~ resource ~ "': " ~ PHYSFS_getLastError().fromStringz());
        else {
                T res = new T();
                res.error();
                return res;
            }
        }
        uint length = cast(uint) PHYSFS_fileLength(file);
        if (length == -1) {
            debug assert(0,
                "Length of resource '" ~ resource ~ "' can't be determined: " ~ PHYSFS_getLastError().fromStringz());
        else {
                T res = new T();
                res.error();
                return res;
            }
        }
        ubyte[] data = new ubyte[length];
        auto result = PHYSFS_read(file, data.ptr, 1, length);
        if (result == -1) {
            debug assert(0,
                "Error while reading resource '" ~ resource ~ "': " ~ PHYSFS_getLastError().fromStringz());
        else {
                T res = new T();
                res.error();
                return res;
            }
        }
        auto ret = loadResource!T(data);
        loaded.reference(ret);
        return ret;
    }
    /// Unloads all resources
    void unload() {
        loaded.destroy();
    }

private:
    SimpleResourceProviderManager loaded;
}
