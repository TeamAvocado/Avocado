import std.stdio;

import avocado.engine;
import avocado.entity.system;
import avocado.entity.entity;
import avocado.entity.world;
import avocado.utilities.fpslimiter;

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
	FPSLimiter limiter = new FPSLimiter(30);
	engine.world.addSystem!EntityOutput;

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
