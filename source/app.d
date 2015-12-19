import std.stdio;

import avocado.core.util;
import avocado.core.engine;
import avocado.core.entity.component;
import avocado.core.entity.system;
import avocado.core.entity.entity;
import avocado.core.entity.world;
import avocado.core.utilities.fpslimiter;
import avocado.core.utilities.matrixstack;
import avocado.core.resource.defaultproviders;
import avocado.core.display.bitmap;
import avocado.core.display.iview;
import avocado.core.display.irenderer;

import avocado.physfs.resourcemanager;
import avocado.sdl2;
import avocado.gl3;

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
                if ((position = entity.get!PositionComponent) !is null
                        && (velocity = entity.get!VelocityComponent) !is null) {
                    position.position += velocity.velocity;
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
    mixin MatrixStack!"modelview";
    float time = 0;

public:
    this(SDLWindow view, ICommonRenderer renderer) {
        this.renderer = renderer;
        this.view = view;
        projection = perspective(view.width, view.height, 45.0f, 0.01f, 100.0f);
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
                if ((position = entity.get!PositionComponent) !is null
                        && (rect = entity.get!MeshComponent) !is null) {
                    modelview.push();
                    modelview.top *= mat4.translation(position.x, position.y, position.z).rotate(time, vec3(0, 0, 1));
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

final struct PositionComponent {
    vec3 position;
    alias position this;
    mixin(ComponentBase!PositionComponent);

    string toString() const {
        return format("Position(%s, %s, %s)", position.x, position.y, position.z);
    }
}

final struct VelocityComponent {
    vec3 velocity;
    alias velocity this;
    mixin(ComponentBase!VelocityComponent);

    string toString() const {
        return format("Velocity(%s, %s, %s)", velocity.x, velocity.y, velocity.z);
    }
}

final struct MeshComponent {
    GLTexture tex;
    GL3ShaderProgram shader;
    GL3MeshCommon mesh;
    mixin(ComponentBase!MeshComponent);

    string toString() const {
        return format("Mesh %s", cast(size_t)&mesh);
    }
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

        auto resources = new ResourceManager(args[0]);
        resources.prepend("res");
        string data = resources.load!TextProvider("test.txt").value;
        writeln("Without packs: ", data);
        if (fs.exists("packs")) {
            auto packs = fs.dirEntries("packs", "*.{pack,zip}", fs.SpanMode.shallow,
                false);
            foreach (pack; packs)
                resources.prepend(pack);
        }
        data = resources.load!TextProvider("test.txt").value;
        writeln("With packs: ", data);

        //world.add!q{
        //    PositionComponent: vec3(0, 0, 2)
        //}("Bob");
        // PLANNED

        //dfmt off
        auto mesh = new GL3MeshCommon();
        mesh.primitiveType = PrimitiveType.TriangleStrip;
        mesh.addIndexArray([0, 1, 2, 3]);
        mesh.addPositionArray([vec3(0, 0, 0), vec3(0, 10, 0), vec3(10, 0, 0), vec3(10, 10, 0)]);
        mesh.addTexCoordArray([vec2(0, 0), vec2(0, 1), vec2(1, 0), vec2(1, 1)]);
        mesh.addNormalArray([vec3(0, 0, 1), vec3(0, 0, 1), vec3(0, 0, 1), vec3(0, 0, 1)]);
        mesh.generate();
        //dfmt on

        auto shader = new GL3ShaderProgram();
        shader.attach(new GLShaderUnit(ShaderType.Fragment, import("texture.frag"))).attach(
            new GLShaderUnit(ShaderType.Vertex, import("default.vert")));
        shader.create(renderer);
        shader.registerUniform("modelview");
        shader.registerUniform("projection");
        shader.registerUniform("tex");
        shader.set("tex", 0);

        auto tex = new GLTexture();
        auto a = 255;
        auto bmp = Bitmap(64, 64, []);
        for (int i = 0; i < 64 * 64 * 4; i++)
            bmp.pixels ~= cast(ubyte) uniform(0, 255);
        tex.fromBitmap(bmp);

        //dfmt off
        Entity e = world.newEntity("Bob")
            .add!PositionComponent(vec3(0, 0, -2))
            .add!MeshComponent(tex, shader, mesh)
            .create();
        //dfmt on

        Entity e2 = world.newEntity("Anna");
        e2.finalize();

        start();
        while (true) {
            if (!update)
                break;
            limiter.wait();
        }

        stop();
    }
    return 0;
}
