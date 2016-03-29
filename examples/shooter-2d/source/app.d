module app;

import components;
import display;
import logic;
import level;
import post;

import avocado.core;
import avocado.physfs.resourcemanager;
import avocado.sdl2;
import avocado.gl3;
import avocado.bmfont;

alias View = SDLWindow;
alias Renderer = GL3Renderer;
alias ShaderUnit = GLShaderUnit;
alias Shader = GL3ShaderProgram;
alias Shape = GL3ShapePosition;
alias Texture = GLTexture;
alias Font = BMFont!(Texture, ResourceManager);

Shape makeEntityShape(vec2[] pos) {
	auto shape = cast(Shape)new Shape().addPositionArray(pos).generate();
	shape.primitiveType = PrimitiveType.LineLoop;
	return shape;
}

Shape makeCircleShape(int edges, float radius) {
	vec2[] pos;
	for (float i = 0; i < PI * 2; i += PI * 2 / edges) {
		pos ~= vec2(sin(i) * radius, cos(i) * radius);
	}
	return makeEntityShape(pos);
}

class Game {
public:
	Event!() onTick;
	Event!() onEntityOutOfBounds;
	Event!() onEntityKilled;
	Event!Entity onEntityGenericDeath;
	ulong score = 0;
	Level level;

	int run() {
		engine = new Engine();
		with (engine) {
			auto window = new View(900, 900, "Example Game");
			auto renderer = new Renderer(GLGUIArguments(true, 100, 100, true));
			std.stdio.writeln("renderer = ", renderer);
			world = add(window, renderer);
			std.stdio.writeln("world = ", world);

			auto res = new ResourceManager();
			res.prepend("res_example1");
			res.prependAll("packs", "*.{pack,zip}");

			FPSLimiter limiter = new FPSLimiter(120);
			GL3Framebuffer origFb = new GL3Framebuffer(No.depth);
			GL3Framebuffer fb1 = new GL3Framebuffer(No.depth);
			GL3Framebuffer fb2 = new GL3Framebuffer(No.depth);
			origFb.create(window.width, window.height, TextureFilterMode.Nearest);
			fb1.create(window.width / 2, window.height / 2, TextureFilterMode.Linear);
			fb2.create(window.width / 2, window.height / 2, TextureFilterMode.Linear);

			ShaderUnit defaultVert = new ShaderUnit(ShaderType.Vertex, import("shape.vert"), true);
			ShaderUnit postVert = new ShaderUnit(ShaderType.Vertex, import("post.vert"), true);
			ShaderUnit defaultFrag = new ShaderUnit(ShaderType.Fragment, import("texture.frag"), true);
			ShaderUnit hpFrag = new ShaderUnit(ShaderType.Fragment, import("hp.frag"), true);
			ShaderUnit hblurFrag = new ShaderUnit(ShaderType.Fragment, import("hblur.frag"), true);
			ShaderUnit vblurFrag = new ShaderUnit(ShaderType.Fragment, import("vblur.frag"), true);
			ShaderUnit neonFrag = new ShaderUnit(ShaderType.Fragment, import("neon.frag"), true);
			ShaderUnit particleVert = new ShaderUnit(ShaderType.Vertex, import("particle.vert"), true);
			ShaderUnit particleFrag = new ShaderUnit(ShaderType.Fragment, import("particle.frag"), true);
			ShaderUnit textVert = new ShaderUnit(ShaderType.Vertex, import("text.vert"), true);

			Shader displayShader = new Shader(renderer, defaultVert, defaultFrag);
			Shader hpShader = new Shader(renderer, defaultVert, hpFrag);
			Shader hblurShader = new Shader(renderer, postVert, hblurFrag);
			Shader vblurShader = new Shader(renderer, postVert, vblurFrag);

			Shader neonShader = new Shader(renderer, postVert, neonFrag);
			neonShader.set("blurred", 0);
			neonShader.set("original", 1);

			Shader particleShader = new Shader(renderer, particleVert, particleFrag);
			Shader textShader = new Shader(renderer, textVert, defaultFrag);
			
			Font font = res.load!Font("fonts/roboto.fnt", res, "fonts/");

			world.addSystem!PostStart(window, renderer, origFb);
			world.addSystem!DisplaySystem(this, window, renderer, font, hpShader, particleShader, textShader);
			world.addSystem!LogicSystem(this);
			world.addSystem!PostEnd(window, renderer, origFb, fb1, fb2, hblurShader, vblurShader, neonShader);

			auto s = min(window.width, window.height);
			renderer.resize(s, s);

			window.onResized ~= (w, h) { auto s = min(w, h); renderer.resize(s, s); };

			level = Level.fromFile(this, res, world, "level/level1.lvl");

			renderer.bind2D();

			glEnable(GL_LINE_SMOOTH);
			glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glPointSize(2);
			renderer.lineWidth = 2;

			_bulletShapeMaxLOD = makeCircleShape(16, 1);
			_bulletShapeMedLOD = makeCircleShape(10, 1);
			_bulletShapeMinLOD = makeCircleShape(6, 1);

			mixin(createEntity!("Player", q{
				EntityDisplay: makeEntityShape([vec2(0, -2), vec2(1.7321f, 1), vec2(-1.7321f, 1)]), vec4(0, 1, 0, 1)
				Health: 5, 5
				Collisions: ColliderGroup.player, [CircleCollider(1.5f)]
				Position: vec2(50, 50)
				Boxed: FixAction.resolve
				KeyboardControl: Key.Up, Key.Down, Key.Left, Key.Right, Key.Space
			}));

			onTick ~= &tickLevel;

			start();
			while (update)
				limiter.wait();
			stop();
		}
		return 0;
	}

	void tickLevel() {
		level.update(world.delta);
	}

	void shoot(vec2 pos, vec2 direction, float speed, float size, bool player) {
		mixin(createEntity!("Bullet", q{
			EntityDisplay: bulletShapeForSize(size), player ? _playerBulletColor : _enemyBulletColor, mat4.scaling(size, size, 1), true
			Health: 1, 1, 0, true
			Collisions: player ? ColliderGroup.player : ColliderGroup.enemy, [CircleCollider(size)], true
			Position: pos
			Boxed: FixAction.kill
			LinearVelocity: direction.normalized * speed
		}));
	}

	Shape bulletShapeForSize(float size) {
		if (size < 1)
			return _bulletShapeMinLOD;
		else if (size < 3.5f)
			return _bulletShapeMedLOD;
		else
			return _bulletShapeMaxLOD;
	}

private:
	vec4 _playerBulletColor = vec4(0, 1, 0, 0.25);
	vec4 _enemyBulletColor = vec4(1, 0, 0, 0.4);
	Shape _bulletShapeMaxLOD;
	Shape _bulletShapeMedLOD;
	Shape _bulletShapeMinLOD;
	Engine engine;
	World world;
}

int main(string[] args) {
	return new Game().run;
}
