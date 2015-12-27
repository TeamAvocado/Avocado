import std.stdio;

import avocado.core.util;
import avocado.core.engine;
import avocado.core.entity.component;
import avocado.core.entity.system;
import avocado.core.entity.entity;
import avocado.core.entity.world;
import avocado.core.utilities.fpslimiter;
import avocado.core.resource.defaultproviders;
import avocado.core.display.bitmap;
import avocado.core.display.iview;
import avocado.core.display.irenderer;

import avocado.physfs.resourcemanager;
import avocado.sdl2;
import avocado.gl3;
import avocado.assimp;

import fs = std.file;
import std.path;
import std.format;
import std.random;

/// Example entity system
final class EntityOutput : ISystem {
public:
	/// Outputs the delta and every
	final void update(World world) {
		foreach (entity; world.entities) {
			if (entity.alive) {
				PositionComponent* position;
				VelocityComponent* velocity;
				if ((position = entity.get!PositionComponent) !is null && (velocity = entity.get!VelocityComponent) !is null) {
					position.value += velocity.value;
				}
			}
		}
	}
}

final class Movement : ISystem {
public:
	/// Outputs the delta and every
	final void update(World world) {
		foreach (entity; world.entities) {
			if (entity.alive) {
				PositionComponent* position;
				MovementComponent* movement;
				if ((position = entity.get!PositionComponent) !is null && (movement = entity.get!MovementComponent) !is null) {
					if (Keyboard.state.isKeyDown(movement.value[0]))
						position.value.z -= world.delta * 10;
					if (Keyboard.state.isKeyDown(movement.value[1]))
						position.value.z += world.delta * 10;
					if (Keyboard.state.isKeyDown(movement.value[2]))
						position.value.x -= world.delta * 10;
					if (Keyboard.state.isKeyDown(movement.value[3]))
						position.value.x += world.delta * 10;
				}
			}
		}
	}
}

final class Renderer3D : ISystem {
private:
	ICommonRenderer renderer;
	IView view;
	mat4 projection;
	MatrixStack!mat4 modelview;
	float time = 0;

public:
	this(SDLWindow view, ICommonRenderer renderer) {
		this.renderer = renderer;
		this.view = view;
		projection = perspective(view.width, view.height, 90.0f, 0.01f, 100.0f);
	}

	/// Draws the entities
	final void update(World world) {
		time += world.delta;
		renderer.begin(view);
		renderer.clear();
		foreach (entity; world.entities) {
			if (entity.alive) {
				PositionComponent* position;
				MeshComponent* rect;
				if ((position = entity.get!PositionComponent) !is null && (rect = entity.get!MeshComponent) !is null) {
					modelview.push();
					modelview.top *= mat4.rotation(time, vec3(0, 1, 0)).translate(position.value);
					rect.tex.bind(renderer, 0);
					rect.shader.bind(renderer);
					rect.shader.set("projection", projection);
					rect.shader.set("modelview", modelview.top);
					renderer.drawMesh(rect.mesh);
					modelview.pop();
				}
			}
		}
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
	mixin ComponentBase!MeshComponent;

	string toString() const {
		return format("Mesh %x", cast(size_t)&mesh);
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
		auto window = new SDLWindow("Example");
		auto renderer = new GL3Renderer;
		auto world = add(window, renderer);

		FPSLimiter limiter = new FPSLimiter(60);
		world.addSystem!EntityOutput;
		world.addSystem!Renderer3D(window, renderer);
		world.addSystem!Movement;

		auto resources = new ResourceManager(args[0]);
		resources.prepend("res");
		resources.prependAll("packs", "*.{pack,zip}");

		//world.add!q{
		//    PositionComponent: vec3(0, 0, 2)
		//}("Bob");
		// PLANNED

		auto shader = new GL3ShaderProgram();
		shader.attach(new GLShaderUnit(ShaderType.Fragment, import("texture.frag"))).attach(new GLShaderUnit(ShaderType.Vertex,
			import("default.vert")));
		shader.create(renderer);
		shader.register(["modelview", "projection", "tex"]);
		shader.set("tex", 0);

		auto bus = resources.load!Scene("models/bus.obj").value.meshes[0].toGLMesh;
		auto tex = resources.load!GLTexture("texture/bus.png");

		//dfmt off
        world.newEntity("Bus")
            .add!PositionComponent(vec3(0, -4, -10))
            .add!MeshComponent(tex, shader, bus)
            .add!MovementComponent(cast(Key[4]) [Key.W, Key.S, Key.A, Key.D])
            .create();
        //dfmt on

		renderer.setupDepthTest(DepthFunc.Less);

		start();
		while (update)
			limiter.wait();
		stop();
	}
	return 0;
}
