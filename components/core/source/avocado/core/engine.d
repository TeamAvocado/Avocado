module avocado.core.engine;

import avocado.core.entity.world;
import avocado.core.event;
import avocado.core.display.iview;
import avocado.core.display.irenderer;

import std.datetime;

/// The avocado engine
final class Engine {
public:
	/// Constructs the engine class
	this() {
	}

	/**
		Calculates the delta and updates the world.
		Run this in every tick of the main loop.
	*/
	bool update() {
		deltaTimer.stop();
		auto delta = deltaTimer.peek.to!("seconds", double);
		deltaTimer.reset();
		deltaTimer.start();

		foreach (ref view; _views) {
			if (!view.view.update())
				return false;
			view.world.delta = delta;
			view.world.tick();
		}
		return true;
	}

	/// The start event subscription list
	void start() {
		deltaTimer.reset();
		deltaTimer.start();
		_start();
	}

	/// The stop event subscription list
	void stop() {
		_stop();
	}

	/// Adds a view to the engine
	World add(IView view, IRenderer renderer) {
		renderer.register(view);
		auto world = new World();
		_views ~= ViewRenderer(view, renderer, world);
		return world;
	}

	ref Trigger onStart() {
		return _start;
	}

	ref Trigger onStop() {
		return _stop;
	}

private:
	struct ViewRenderer {
		IView view;
		IRenderer renderer;
		World world;
	}

	bool quit;
	ViewRenderer[] _views;

	StopWatch deltaTimer;

	Trigger _start;
	Trigger _stop;
}
