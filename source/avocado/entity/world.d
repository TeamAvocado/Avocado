module avocado.entity.world;

import avocado.entity.entity;
import avocado.entity.system;

final class World {
public:
	this() {
		_delta = 0;
	}

	Entity newEntity(arg...)(arg args) {
		auto e = new Entity(this, args);
		_entities ~= e;
		return e;
	}

	T addSystem(T : ISystem, arg...)(arg args) {
		auto c = new T(args);
		_systems[T.stringof] = c;
		return c;
	}

	void tick() {
		foreach (ISystem system; _systems)
			system.update(this);
	}

	@property ref double delta() { return _delta; }
	@property ref Entity[] entities() { return _entities; }
	@property ref ISystem[string] systems() { return _systems; }
private:
	double _delta;
	Entity[] _entities;
	ISystem[string] _systems;
}
