module avocado.core.engine;

import avocado.core.entity.world;
import avocado.core.event;
import avocado.core.display.iview;
import avocado.core.display.irenderer;

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
    bool update() {
        deltaTimer.stop();
        world.delta = deltaTimer.peek.usecs / 1_000_000.0;
        deltaTimer.reset();
        deltaTimer.start();

        foreach(ref view; _views)
            if(!view.update())
                return false;
        world.tick();
        return true;
    }

    ///Gets the world
    @property World world() {
        return _world;
    }

    /// The start event subscription list
    @property Event!() start() {
        return _start;
    }

    /// The stop event subscription list
    @property Event!() stop() {
        return _stop;
    }

    /// Adds a view to the engine
    void add(IView view, IRenderer renderer) {
        renderer.register(view);
        _views ~= view;
    }

private:
    bool quit;
    World _world;
    IView[] _views;

    StopWatch deltaTimer;

    Event!() _start;
    Event!() _stop;
}
