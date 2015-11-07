module avocado.core.engine;

import avocado.core.entity.world;
import avocado.core.event;

import std.datetime : StopWatch;
/**
	The avocado engine
*/
final class Engine {
public:
	/// Constructs the engine class
	this() {
		_world = new World();
	}

	/**
		Calculates the delta and updates the world.
		Run this in every tick of the main loop.
	*/
	void update() {
		deltaTimer.stop();
		world.delta = deltaTimer.peek.usecs/1_000_000.0;
		deltaTimer.reset();
		deltaTimer.start();
		world.tick();
	}

	///Gets the world
	@property World world() { return _world; }
	/// The start event subscription list
	@property Event!() start() { return _start; }
	/// The stop event subscription list
	@property Event!() stop() { return _stop; }
private:
	bool quit;
	World _world;

	StopWatch deltaTimer;

	Event!() _start;
	Event!() _stop;
}
