module logic;

import app;

import avocado.core;
import avocado.gl3;
import avocado.input;

import std.math;

import components;

vec2 rotateVector(vec2 vector, float amount) {
	float x = vector.x;
	vector.x = x * cos(amount) - vector.y * sin(amount);
	vector.y = x * sin(amount) + vector.y * cos(amount);
	return vector;
}

class LogicSystem : ISystem {
	this(Game game) {
		_game = game;
	}

	final void update(World world) {
		_game.onTick();
		foreach (entity; world.entities) {
			if (entity.alive) {
				{
					KeyboardControl* keys;
					Position* pos;
					if (entity.fetch(keys, pos)) {
						vec2 deltaPos = vec2(0, 0);
						if (Keyboard.state.isKeyPressed(keys.up))
							deltaPos.y -= 1;
						if (Keyboard.state.isKeyPressed(keys.down))
							deltaPos.y += 1;
						if (Keyboard.state.isKeyPressed(keys.left))
							deltaPos.x -= 1;
						if (Keyboard.state.isKeyPressed(keys.right))
							deltaPos.x += 1;
						if (Keyboard.state.isKeyPressed(keys.shootKey) && keys.shoot())
							_game.shoot(pos.position, vec2(0, -1), 55, 1, true);
						pos.position += deltaPos.normalized * world.delta * 40;
					}
				}
				{
					BulletSpawner* bullet;
					Position* pos;
					if (entity.fetch(bullet, pos)) {
						if (bullet.shoot()) {
							foreach (angle; bullet.angles)
								_game.shoot(pos.position, vec2(0, 1)
									.rotateVector(angle / 180.0f * 3.1415926f + pos.rotation), bullet.speed, bullet.radius,
									false);
						}
					}
				}
				{
					LinearVelocity* linear;
					LinearDamping ldamping;
					AngularVelocity* angular;
					AngularDamping adamping;
					AxisVelocity* axis;
					AxisDamping axdamping;
					Position* pos;
					if (entity.fetch(pos)) {
						if (entity.fetch(angular)) {
							if (entity.fetch(adamping))
								angular.velocity *= pow(1 - adamping.damping, world.delta);
							pos.rotation += angular.velocity * world.delta;
						}
						if (entity.fetch(linear)) {
							if (entity.fetch(ldamping)) {
								linear.velocity.x *= pow(1 - ldamping.damping.x, world.delta);
								linear.velocity.y *= pow(1 - ldamping.damping.y, world.delta);
							}
							if (pos.rotation != 0)
								pos.position += linear.velocity.rotateVector(pos.rotation) * world.delta;
							else
								pos.position += linear.velocity * world.delta;
						}
						if (entity.fetch(axis)) {
							if (entity.fetch(axdamping)) {
								axis.velocity.x *= pow(1 - axdamping.damping.x, world.delta);
								axis.velocity.y *= pow(1 - axdamping.damping.y, world.delta);
							}
							pos.position += axis.velocity * world.delta;
						}
					}
				}
				{
					Collisions collider, colliderOther;
					Position pos, posOther;
					Health* health, healthOther;
					if (entity.fetch(collider, pos, health))
						foreach (ref other; world.entities)
							if (entity != other && other.alive && other.fetch(colliderOther, posOther, healthOther)
									&& collider.collides(pos.position, colliderOther, posOther.position)) {
								health.hit();
								healthOther.hit();
								if (health.hitpoints == 0 && !health.bullet) {
									_game.score += health.maxhp * 10;
									_game.onEntityKilled();
								}
								if (healthOther.hitpoints == 0 && !healthOther.bullet) {
									_game.score += health.maxhp * 10;
									_game.onEntityKilled();
								}
							}
				}
				{
					Boxed boxed;
					Position* pos;
					if (entity.fetch(boxed, pos)) {
						if (boxed.action == FixAction.kill && (pos.position.x < -2 || pos.position.y < -2
								|| pos.position.x > 102 || pos.position.y > 102))
							entity.alive = false;
						else if (boxed.action == FixAction.resolve) {
							if (pos.position.x < 0)
								pos.position.x = 0;
							if (pos.position.y < 0)
								pos.position.y = 0;
							if (pos.position.x > 100)
								pos.position.x = 100;
							if (pos.position.y > 100)
								pos.position.y = 100;
						} else if (boxed.action == FixAction.wrapXkillY) {
							if (pos.position.x < -5)
								pos.position.x = 104.9f;
							Health h;
							if (entity.fetch(h))
								if (pos.position.y < -10 && h.bullet)
									entity.alive = false;
							if (pos.position.x > 105)
								pos.position.x = -4.9f;
							if (pos.position.y > 105)
								entity.alive = false;
						}
						if (!entity.alive) {
							Health h;
							if (entity.fetch(h))
								if (!h.bullet)
									_game.onEntityOutOfBounds();
						}
					}
				}
				if (!entity.alive)
					_game.onEntityGenericDeath(entity);
			}
		}
	}

private:
	Game _game;
}
