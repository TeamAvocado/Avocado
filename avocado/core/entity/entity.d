module avocado.core.entity.entity;

import avocado.core.entity.component;
import avocado.core.entity.world;

///
final class Entity {
public:
    this(World world, string name) {
        this._world = world;
        this._name = name;
    }

    Entity finalize() {
        _alive = true;
        return this;
    }
    alias create = finalize;

    @property ref bool alive() {
        return _alive;
    }

    @property ref string name() {
        return _name;
    }

    @property ref World world() {
        return _world;
    }
    
    Entity add(T, Args...)(Args args) {
        T.add(this, args);
        return this;
    }
    
    auto get(T)() {
        return T.get(this);
    }
    
    bool has(T)() {
        return T.get(this) !is null;
    }

    override string toString() {
        return "Entity[\"" ~ _name ~ "\"]";
    }

private:
    bool _alive;
    string _name;
    World _world;
}
