module components;

import app;

import painlessjson;

import avocado.core;
import avocado.gl3;
import avocado.sdl2;

import std.datetime;

struct EntityDisplay {
	Shape shape;
	vec4 color;
	mat4 matrix = mat4.identity;
	bool bullet = false;
	mixin ComponentBase;
}

struct EntityDisplayJson {
	float[][] shape;
	float[] color;
	bool bullet = false;
	EntityDisplay create() {
		vec2[] shapeVerts;
		foreach (vert; shape)
			shapeVerts ~= vec2(vert[0], vert[1]);
		vec4 color = vec4(color[0], color[1], color[2], color[3]);
		return EntityDisplay(makeEntityShape(shapeVerts), color, mat4.identity, bullet);
	}
}

struct Position {
	vec2 position;
	float rotation = 0;
@SerializeIgnore:
	mixin ComponentBase;
}

struct AxisVelocity {
	vec2 velocity;
@SerializeIgnore:
	mixin ComponentBase;
	
	AxisVelocity dup() {
		return AxisVelocity(vec2(velocity.x, velocity.y));
	}
}

struct AxisVelocityJson {
	float[] velocity;
	AxisVelocity create() {
		return AxisVelocity(vec2(velocity[0], velocity[1]));
	}
}

struct LinearVelocity {
	vec2 velocity;
@SerializeIgnore:
	mixin ComponentBase;
	
	LinearVelocity dup() {
		return LinearVelocity(vec2(velocity.x, velocity.y));
	}
}

struct LinearVelocityJson {
	float[] velocity;
	LinearVelocity create() {
		return LinearVelocity(vec2(velocity[0], velocity[1]));
	}
}

struct AngularVelocity {
	float velocity;
@SerializeIgnore:
	mixin ComponentBase;
	
	AngularVelocity dup() {
		return AngularVelocity(velocity);
	}
}

struct AxisDamping {
	vec2 damping;
@SerializeIgnore:
	mixin ComponentBase;
}

struct AxisDampingJson {
	float[] damping;
	AxisDamping create() {
		return AxisDamping(vec2(damping[0], damping[1]));
	}
}

struct LinearDamping {
	vec2 damping;
@SerializeIgnore:
	mixin ComponentBase;
}

struct LinearDampingJson {
	float[] damping;
	LinearDamping create() {
		return LinearDamping(vec2(damping[0], damping[1]));
	}
}

struct AngularDamping {
	float damping;
@SerializeIgnore:
	mixin ComponentBase;
}

struct Health {
	int maxhp;
	int hitpoints;
@SerializeIgnore:
	long lastHit = 0;
	bool bullet = false;
	mixin ComponentBase;

	void hit() {
		long now = Clock.currStdTime;
		if (lastHit + 8.msToHns <= now) {
			lastHit = now;
			hitpoints--;
		}
	}
	
	Health dup() {
		return Health(maxhp, hitpoints, lastHit);
	}
}

long msToHns(long ms) {
	return ms * 100_000;
}

struct KeyboardControl {
	Key up, down, left, right;
	Key shootKey;
	long lastShoot = 0;
@SerializeIgnore:
	mixin ComponentBase;

	bool shoot() {
		long now = Clock.currStdTime;
		if (lastShoot + 10.msToHns <= now) {
			lastShoot = now;
			return true;
		}
		return false;
	}
}

struct BulletSpawner {
	long interval = 20.msToHns;
	float radius = 1;
	float speed = 50;
	long lastShoot = 0;
	float[] angles = [0];
@SerializeIgnore:
	mixin ComponentBase;

	bool shoot() {
		long now = Clock.currStdTime;
		if (lastShoot + interval <= now) {
			lastShoot = now;
			return true;
		}
		return false;
	}
	
	BulletSpawner dup() {
		return BulletSpawner(interval, radius, speed, lastShoot, angles);
	}
}

enum ColliderGroup : ubyte {
	enemy = 0,
	player = 1,
}

struct Collisions {
	ColliderGroup group;
	CircleCollider[] circles = [];
	bool isBullet = false;

	bool collides(vec2 thisPosition, Collisions other, vec2 otherPosition) {
		if (other.group == group)
			return false;
		if (other.isBullet && isBullet)
			return false;
		foreach (circle; circles)
			foreach (otherCircle; other.circles)
				if (circle.collides(thisPosition, otherCircle, otherPosition))
					return true;
		return false;
	}

@SerializeIgnore:
	mixin ComponentBase;
}

struct CollisionsJson {
	ColliderGroup group = ColliderGroup.enemy;
	CircleColliderJson[] circles = [];
	bool isBullet = false;

	Collisions create() {
		CircleCollider[] circ;
		foreach (circle; circles)
			circ ~= circle.create;
		return Collisions(group, circ, isBullet);
	}
}

struct CircleCollider {
	float radius;
	vec2 offset = vec2(0, 0);

	bool collides(vec2 thisPosition, CircleCollider other, vec2 otherPosition) {
		return ((thisPosition + offset) - (otherPosition + other.offset)).length_squared < radius * radius + other.radius * other.radius;
	}
}

struct CircleColliderJson {
	float radius;
	float[] offset;

	CircleCollider create() {
		return CircleCollider(radius, vec2(offset[0], offset[1]));
	}
}

enum FixAction : ubyte {
	resolve,
	kill,
	wrapXkillY
}

struct Boxed {
	FixAction action;
@SerializeIgnore:
	mixin ComponentBase;
}