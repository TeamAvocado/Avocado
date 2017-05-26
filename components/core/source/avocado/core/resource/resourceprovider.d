module avocado.core.resource.resourceprovider;

/// Base interface for any resource loaders
interface IResourceProvider {
	/// Loads a default error resource or does nothing
	void error();
	/// Optional error information for debugging when loading fails
	@property string errorInfo();
	/// Loads a resource from a memory stream
	/// Return false if an error occured and optionally also set errorInfo.
	bool load(ref ubyte[] stream);
	/// Check if a resource manager can read that extension
	bool canRead(string extension);
}

/// Base interface for resource managers (managing paths and file errors)
interface IResourceManager {
	/// Appends search paths. Last element in the arguments list will be last.
	void append(string[] paths...);
	/// Prepends search paths. First element in the arguments list will be first.
	void prepend(string[] paths...);
	///
	void removeSearchPath(string path);
	///
	void clearSearchPaths();
	/// Returns the location of a file
	string findFile(string resource);
	/// Reads raw data from a resource for manual creation.
	bool read(string resource, ref ubyte[] ret);
	/// Loads a resource using a ResourceProvider
	T load(T : IResourceProvider, Args...)(string resource, Args constructArgs);
	/// Unloads all resources
	void unload();
}

/// Loads some resource from a byte stream
static T loadResource(T : IResourceProvider, Args...)(ref ubyte[] stream, Args constructArgs) {
	T resource = new T(constructArgs);
	if (!resource.load(stream)) {
		resource.error();
		debug assert(false, "Failed to load resource. Additional info: " ~ resource.errorInfo);
	}
	return resource;
}

class SimpleResourceProviderManager {
	IResourceProvider[] resources;

	void dispose() {
		foreach (resource; resources)
			resource.destroy();
		resources = null;
	}

	void reference(T : IResourceProvider)(ref T resource) {
		resources ~= resource;
	}
}
