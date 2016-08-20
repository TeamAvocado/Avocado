module avocado.core.entity.world;

import avocado.core.entity.entity;
import avocado.core.entity.system;

import std.string;
import std.conv;

private template ParseEntityBodyLine(string line) {
	static if (line.length >= 2 && line[0] == '/' && line[1] == '/')
		enum ParseEntityBodyLine = "";
	else static if (line.length == 0)
		enum ParseEntityBodyLine = "";
	else {
		enum colon = line.indexOf(':');
		static assert(colon != -1, "A line must contain a colon! (Name: Arguments)");
		enum ParseEntityBodyLine = ".add!(" ~ line[0 .. colon] ~ ")(" ~ line[colon + 1 .. $] ~ ")";
	}
}

private template EntityBody(string templ) {
	enum lineLength = templ.indexOf('\n');
	static if (lineLength == -1)
		enum EntityBody = ParseEntityBodyLine!(templ);
	else
		enum EntityBody = ParseEntityBodyLine!(templ[0 .. lineLength].strip()) ~ EntityBody!(templ[lineLength + 1 .. $].strip());
}

template createEntity(string name, string templ, string world = "world", bool returnIt = false) {
	enum createEntity = world ~ ".newEntity(`" ~ name ~ "`)" ~ EntityBody!templ ~ ".finalize()" ~ (returnIt ? ' ' : ';');
}

///
final class World {
public:
	this() {
		_delta = 0;
	}

	Entity newEntity(Args...)(Args args) {
		auto e = new Entity(this, args);
		_entities ~= e;
		return e;
	}

	T addSystem(T : ISystem, Args...)(Args args) {
		auto c = new T(args);
		_systems ~= c;
		return c;
	}

	void tick() {
		foreach (ISystem system; _systems)
			system.update(this);
	}

	@property ref double delta() {
		return _delta;
	}

	@property ref Entity[] entities() {
		return _entities;
	}

	@property ref ISystem[] systems() {
		return _systems;
	}

private:
	double _delta;
	Entity[] _entities;
	ISystem[] _systems;
}
