import std.stdio;

import avocado.core.engine;
import avocado.core.entity.system;
import avocado.core.entity.entity;
import avocado.core.entity.world;
import avocado.core.utilities.fpslimiter;
import avocado.core.resource.defaultproviders;

import avocado.physfs.resourcemanager;

import fs = std.file;
import std.path;

/// Example entity system
final class EntityOutput : ISystem {
public:
	/// Outputs the delta and every
	final void update(World world) {
		writeln("Delta: ", world.delta());
		foreach (entity; world.entities)
			if (entity.alive)
				writeln("\t", entity);
	}
}


/// The entrypoint of the program
int main(string[] args) {
	Engine engine = new Engine();
	FPSLimiter limiter = new FPSLimiter(60);
	engine.world.addSystem!EntityOutput;

	auto resources = new ResourceManager(args[0]);
	resources.prepend("res");
	string data = resources.load!TextProvider("test.txt").value;
	writeln("Without packs: ", data);
	if(fs.exists("packs")) {
		auto packs = fs.dirEntries("packs", "*.{pack,zip}", fs.SpanMode.shallow, false);
		foreach(pack; packs)
			resources.prepend(pack);
	}
	data = resources.load!TextProvider("test.txt").value;
	writeln("With packs: ", data);

	Entity e = engine.world.newEntity("Bob");
	e.finalize();
	Entity e2 = engine.world.newEntity("Anna");
	e2.finalize();

	engine.start();
	bool quit = false;
	while (!quit) {
		engine.update();

		limiter.wait();
	}

	engine.stop();
	return 0;
}
