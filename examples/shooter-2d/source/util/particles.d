module util.particles;

import app;

import avocado.core;
import avocado.gl3;
import std.algorithm;
import std.random;
import std.math;

alias PositionStream2D = BufferElement!("ParticlePosition", 2, float, false, BufferType.Element, true);
alias ColorStream = BufferElement!("Color", 4, float, false, BufferType.Element, true);

alias ParticleStream = GL3Mesh!(PositionElement2D, PositionStream2D, ColorStream);

final struct ParticleInfo {
	vec2 position;
	vec2 constantVelocity;
	vec2 velocity;
	vec3 color;
	float damping;
	float remainingLife;
}

final struct EmitterInfo {
	ParticleInfo particle;
	vec2 velocity;
	vec2 spreadVelocity;
	float interval;
	int maxSpawn;
	int spawned = 0;
	float time = 0;
}

final class ParticleSystem {
public:
	this(int max = 500, vec2[] particleShape = [vec2(0, 0)], PrimitiveType type = PrimitiveType.Points) {
		_particles = cast(ParticleStream)new ParticleStream().addPositionArray(particleShape).reserveParticlePosition(max).reserveColor(max).generate();
		_particles.primitiveType = type;
		_max = max;
		_positions.length = max;
		_colors.length = max;
		_particleInfos.reserve(max);
		_particles.fillParticlePosition(_positions);
		_particles.fillColor(_colors);
	}

	void spawn(ParticleInfo particle) {
		if (_particleInfos.length < _max) {
			_particleInfos ~= particle;
			return;
		}
		for (size_t i = 0; i < _particleInfos.length; i++) {
			if (_particleInfos[i].remainingLife < 0 || isNaN(_particleInfos[i].remainingLife)) {
				_particleInfos[i] = particle;
				return;
			}
		}
	}

	void emit(EmitterInfo emitter) {
		_emitterInfos ~= emitter;
	}

	void update(float delta) {
		foreach_reverse (i, ref emitter; _emitterInfos) {
			emitter.time += delta;
			emitter.particle.position += emitter.velocity * delta;
			while (emitter.time >= emitter.interval) {
				auto part = emitter.particle;
				part.velocity += vec2(uniform(-1.0f, 1.0f) * emitter.spreadVelocity.x, uniform(-1.0f, 1.0f) * emitter.spreadVelocity.y);
				spawn(part);
				emitter.spawned++;
				emitter.time -= emitter.interval;
			}
			if (emitter.spawned >= emitter.maxSpawn && emitter.maxSpawn != -1)
				_emitterInfos = _emitterInfos.remove(i);
		}
		foreach_reverse (i, ref particle; _particleInfos) {
			if (particle.damping != 0)
				particle.velocity *= pow(particle.damping, delta);
			particle.position += particle.constantVelocity * delta + particle.velocity * delta;
			particle.remainingLife -= delta;
		}
		activeParticles = cast(int)_particleInfos.length;
		for (int i = 0; i < activeParticles; i++) {
			if (i < _particleInfos.length && _particleInfos[i].remainingLife > 0) {
				_positions[i] = _particleInfos[i].position;
				_colors[i] = vec4(_particleInfos[i].color, _particleInfos[i].remainingLife);
			} else {
				_positions[i] = vec2(float.nan, float.nan);
				_colors[i] = vec4(0, 0, 0, 0);
			}
		}
	}

	void draw(Renderer renderer, Shader shader) {
		_particles.fillParticlePosition(_positions);
		_particles.fillColor(_colors);
		renderer.bind(shader);
		renderer.drawMeshInstanced(_particles, activeParticles);
	}

private:
	int _max;
	int activeParticles;
	vec2[] _positions;
	vec4[] _colors;
	ParticleInfo[] _particleInfos;
	EmitterInfo[] _emitterInfos;
	ParticleStream _particles;
}
