import std.stdio;

import avocado.core;
import avocado.physfs.resourcemanager;
import avocado.sdl2;
import avocado.gl3;
import avocado.assimp;

import fs = std.file;
import std.path;
import std.format;
import std.random;

alias Renderer = GL3Renderer;
alias View = SDLWindow;

final class Movement : ISystem {
public:
	/// Outputs the delta and every
	final void update(World world) {
		foreach (entity; world.entities) {
			if (entity.alive) {
				PositionComponent* position;
				MovementComponent movement;
				if (entity.fetch(position, movement)) {
					if (Keyboard.state.isKeyPressed(movement.value[0]))
						position.value.z -= world.delta * 10;
					if (Keyboard.state.isKeyPressed(movement.value[1]))
						position.value.z += world.delta * 10;
					if (Keyboard.state.isKeyPressed(movement.value[2]))
						position.value.x -= world.delta * 10;
					if (Keyboard.state.isKeyPressed(movement.value[3]))
						position.value.x += world.delta * 10;
				}
			}
		}
	}
}

final class DisplaySystem : ISystem {
private:
	Renderer renderer;
	View view;
	float time = 0;

public:
	this(View view, Renderer renderer) {
		this.renderer = renderer;
		this.view = view;
		renderer.projection.top = perspective(view.width, view.height, 90.0f, 0.01f, 100.0f);
	}

	/// Draws the entities
	final void update(World world) {
		time += world.delta;
		renderer.begin(view);
		renderer.clear();
		foreach (entity; world.entities) {
			if (entity.alive) {
				PositionComponent position;
				MeshComponent mesh;
				if (entity.fetch(position, mesh)) {
					renderer.modelview.push();
					renderer.modelview.top *= mat4.rotation(time, vec3(0, 1, 0)).translate(position.value);
					mesh.tex.bind(renderer, 0);
					renderer.bind(mesh.shader);
					renderer.drawMesh(mesh.mesh);
					renderer.modelview.pop();
				}
			}
		}

		renderer.bind2D();
		foreach (entity; world.entities) {
			if (entity.alive) {
				{
					RectangleComponent rect;
					if (entity.fetch(rect)) {
						renderer.drawRectangle(rect.tex, rect.rect);
					}
				}
				{
					SolidComponent rect;
					if (entity.fetch(rect)) {
						renderer.fillRectangle(rect.rect, rect.color);
					}
				}
				{
					ControlComponent control;
					if (entity.fetch(control)) {
						control.control.draw(renderer);
					}
				}
			}
		}
		renderer.bind3D();
		renderer.end(view);
	}
}

mixin BasicComponent!("PositionComponent", vec3);
mixin BasicComponent!("VelocityComponent", vec3);
mixin BasicComponent!("MovementComponent", Key[4]);

final struct MeshComponent {
	GLTexture tex;
	GL3ShaderProgram shader;
	GL3MeshCommon mesh;
	mixin ComponentBase;

	string toString() const {
		return format("Mesh %x", cast(size_t)&mesh);
	}
}

final struct RectangleComponent {
	GLTexture tex;
	vec4 rect;
	mixin ComponentBase;

	string toString() const {
		return format("Texture Rectangle %s,%s %sx%s (null=%s)", rect.x, rect.y, rect.z, rect.w, tex is null);
	}
}

final struct SolidComponent {
	vec4 color;
	vec4 rect;
	mixin ComponentBase;

	string toString() const {
		return format("Solid Rectangle %d,%d %dx%d", rect.x, rect.y, rect.z, rect.w);
	}
}

final struct ControlComponent {
	Control control;
	mixin ComponentBase;

	string toString() const {
		return format("Control %x", &control);
	}
}

auto toGLMesh(AssimpMeshData from) {
	auto mesh = new GL3MeshCommon();
	mesh.primitiveType = PrimitiveType.Triangles;
	foreach (indices; from.indices)
		mesh.addIndexArray(indices);
	mesh.addPositionArray(from.vertices);
	foreach (texCoord; from.texCoords[0])
		mesh.addTexCoord(texCoord.xy);
	mesh.addNormalArray(from.normals);
	mesh.generate();
	return mesh;
}

/// The entrypoint of the program
int main(string[] args) {
	Engine engine = new Engine();
	with (engine) {
		auto window = new View("Example");
		auto renderer = new Renderer;
		auto world = add(window, renderer);

		FPSLimiter limiter = new FPSLimiter(120);
		world.addSystem!DisplaySystem(window, renderer);
		world.addSystem!Movement;

		window.onResized ~= (w, h) {
			renderer.resize(w, h);
			renderer.projection.top = perspective(w, h, 90.0f, 0.01f, 100.0f);
		};

		auto resources = new ResourceManager();
		resources.prepend("res");
		resources.prependAll("packs", "*.{pack,zip}");

		auto shader = new GL3ShaderProgram();
		shader.attach(new GLShaderUnit(ShaderType.Fragment, import("texture.frag"))).attach(new GLShaderUnit(ShaderType.Vertex,
			import("default.vert")));
		shader.create(renderer);
		shader.register(["modelview", "projection", "tex"]);
		shader.set("tex", 0);

		auto bus = resources.load!Scene("models/bus.obj").value.meshes[0].toGLMesh;
		auto tex = resources.load!GLTexture("texture/bus.png");

		mixin(createEntity!("Bus", q{
			PositionComponent: vec3(0, -4, -10)
			MeshComponent: tex, shader, bus
			MovementComponent: cast(Key[4]) [Key.W, Key.S, Key.A, Key.D]
		})); // (

		mixin(createEntity!("2DBus", q{
			RectangleComponent: tex, vec4(64, 64, 128, 128)
		})); // (

		Control control = new Control(window);
		control.width = 128;
		control.height = 256;
		control.x = 8;
		control.y = 0;
		control.background = vec4(1, 1, 1, 1);
		control.alignment = Alignment.MiddleLeft;
		mixin(createEntity!("Sidebar", q{
			ControlComponent: control
		}));

		renderer.setupDepthTest(DepthFunc.Less);

		start();
		while (update)
			limiter.wait();
		stop();
	}
	return 0;
}
