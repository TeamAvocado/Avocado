module avocado.core.entity.entity;

import avocado.core.entity.component;
import avocado.core.entity.world;

import std.conv;
import std.stdio;

template FetchBase(int i) {
	static if (i == -1)
		enum FetchBase = "";
	else
		enum FetchBase = "if(!has!(T[" ~ i.to!string ~ "])) return false; coms[" ~ i.to!string
				~ "] = *get!(T[" ~ i.to!string ~ "]); " ~ FetchBase!(i - 1);
}

///
final class Entity {
public:
	this(World world, string name) {
		this._world = world;
		this._name = name;
	}

	Entity finalize() {
		_alive = true;
		return this;
	}

	alias create = finalize;

	@property ref bool alive() {
		return _alive;
	}

	@property ref string name() {
		return _name;
	}

	@property ref World world() {
		return _world;
	}

	Entity add(T, Args...)(Args args) {
		T.add(this, args);
		return this;
	}

	auto get(T)() {
		return T.get(this);
	}

	bool has(T)() {
		return T.get(this)!is null;
	}

	bool fetch(T...)(ref T coms) if (T.length > 0) {
		mixin(FetchBase!(T.length - 1));
		return true;
	}

	override string toString() {
		return "Entity[\"" ~ _name ~ "\"]";
	}

private:
	bool _alive;
	string _name;
	World _world;
}
