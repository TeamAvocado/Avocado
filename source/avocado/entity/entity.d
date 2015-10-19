module avocado.entity.entity;

import avocado.entity.component;
import avocado.entity.world;

final class Entity {
public:
	this(World world, string name) {
		this._world = world;
		this._name = name;
	}

	void finalize() {
		_alive = true;
	}

	@property ref bool alive() { return _alive; }
	@property ref string name() { return _name; }
	@property ref World world() { return _world; }

	override string toString() {
		import std.format;
		return format("Entity[\"%s\"]", _name);
	}

private:
	bool _alive;
	string _name;
	World _world;
}
