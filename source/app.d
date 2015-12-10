import std.stdio;

import avocado.core.util;
import avocado.core.engine;
import avocado.core.entity.component;
import avocado.core.entity.system;
import avocado.core.entity.entity;
import avocado.core.entity.world;
import avocado.core.utilities.fpslimiter;
import avocado.core.resource.defaultproviders;

import avocado.physfs.resourcemanager;
import avocado.sdl2;
import avocado.gl3;

import fs = std.file;
import std.path;
import std.format;

/// Example entity system
final class EntityOutput : ISystem {
public:
    /// Outputs the delta and every
    final void update(World world) {
        writeln("Delta: ", world.delta());
        foreach (entity; world.entities)
            if (entity.alive)
                writefln("\t%s %s", entity,
                    entity.get!PositionComponent ? (*entity.get!PositionComponent).toString() : "");
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

/// The entrypoint of the program
int main(string[] args) {
    Engine engine = new Engine();
    with (engine) {
        FPSLimiter limiter = new FPSLimiter(60);
        world.addSystem!EntityOutput;

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

        Entity e = world.newEntity("Bob");
        e.add!PositionComponent(vec3(0, 0, 2));
        e.finalize();
        /*
        Entity e = world.newEntity("Bob");
        PositionComponent.addComponent(e, vec3(0, 0, 2));
        e.finalize();*/

        Entity e2 = world.newEntity("Anna");
        e2.finalize();

        SDLWindow window = new SDLWindow("Example");
        GL3Renderer renderer = new GL3Renderer;
        renderer.register(window);

        add(window);
        start();
        while (true) {
            if (!update)
                break;
            renderer.begin(window);

            renderer.end(window);
            limiter.wait();
        }

        stop();
    }
    return 0;
}
