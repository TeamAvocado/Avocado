module avocado.core.resource.defaultproviders;

import avocado.core.resource.resourceprovider;

import std.traits;

/// Generic string loading and validation from a file
class TextProvider : IResourceProvider {
    /// Contains file value
    string value = "";

    /// Unused
    void error() {
    }
    /// Unused
    @property string errorInfo() {
        return "";
    }

    /// Loads a resource from a memory stream
    bool load(ref ubyte[] stream) {
        value = cast(string) stream.idup;
        return true;
    }

    /// Always true
    bool canRead(string extension) {
        return true;
    }

    /// Can cast to a string and will return value
    T opCast(T)() if (isSomeString!T) {
        return cast(T) value;
    }
}
