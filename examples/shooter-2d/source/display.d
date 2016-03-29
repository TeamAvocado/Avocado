module display;

import app;

import avocado.core;
import avocado.gl3;

import std.random;

import components;
import util.particles;
import util.font;

class DisplaySystem : ISystem {
private:
	Renderer renderer;
	View view;
	Shader hpshader, particleshader, textshader;
	Shape healthbar;
	ParticleSystem particles;
	Game game;
	Text text;

public:
	this(Game game, View view, Renderer renderer, Font font, Shader hpshader, Shader particleshader, Shader textshader) {
		this.game = game;
		this.renderer = renderer;
		this.view = view;
		this.hpshader = hpshader;
		this.particleshader = particleshader;
		this.textshader = textshader;
		healthbar = cast(Shape)new Shape().addPositionArray([vec2(-2, 0), vec2(2, 0)]).generate();
		healthbar.primitiveType = PrimitiveType.LineStrip;
		particles = new ParticleSystem();
		text = new Text(font);
	}

	void explode(vec2 position, vec3 color, float scale) {
		if (scale > 5)
			scale = 5;
		if (scale < 0.5f)
			scale = 0.5f;
		particles.emit(EmitterInfo(ParticleInfo(position, vec2(0, 10) * scale, vec2(0, -6) * scale, color, 0.2f, 1.0f),
			vec2(0, 4) * scale, vec2(20, 20) * scale, 0.0001f, cast(int) (20 * scale)));
	}

	final void update(World world) {
		foreach (entity; world.entities) {
			if (entity.alive) {
				{
					Health hp;
					if (entity.fetch(hp)) {
						if (hp.hitpoints <= 0) {
							entity.alive = false;
							EntityDisplay display;
							Position p = Position(vec2(0, 0));
							if (entity.fetch(p, display)) {
								if (!display.bullet)
									explode(p.position, display.color.rgb, hp.maxhp * 0.5f);
							}
						}
					}
				}
				{
					EntityDisplay display;
					Position p = Position(vec2(0, 0));
					if (entity.fetch(p, display)) {
						renderer.modelview.push();
						renderer.modelview.top *= mat4.zrotation(p.rotation).translate(p.position.x, p.position.y, 0) * display.matrix;
						renderer.fillShape(display.shape, vec2(0, 0), display.color);
						renderer.modelview.pop();
						assert(!p.position.x.isNaN);
						assert(!p.position.y.isNaN);

						Health health;
						if (entity.fetch(health)) {
							if (health.hitpoints != 0 && health.maxhp != 0 && health.hitpoints != health.maxhp) {
								renderer.modelview.push();
								renderer.modelview.top *= mat4.translation(p.position.x, p.position.y + 3, 0);
								renderer.bind(hpshader);
								hpshader.set("hp", health.hitpoints / cast(float)health.maxhp);
								renderer.drawMesh(healthbar);
								renderer.modelview.pop();
							}
						}
					}
				}
				if (!entity.alive)
					game.onEntityGenericDeath(entity);
			}
		}
		particles.update(world.delta);
		particles.draw(renderer, particleshader);
		text.text = "Score: "d ~ game.score.to!dstring;
		renderer.modelview.push();
		renderer.modelview.top *= mat4.scaling(75, 50, 1).translate(2, 98, 0);
		text.draw(renderer, textshader);
		renderer.modelview.pop();
	}
}
