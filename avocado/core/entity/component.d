module avocado.core.entity.component;

///
mixin template ComponentBase(T, int startingAmount = 8) {
    import std.conv : to;

    public static auto add(arg...)(Entity entity, arg args) {
        return components[entity] = new T(args);
    }

    public static auto get(Entity entity) {
        auto p = entity in components;
        return p ? *p : null;
    }

    private static T*[Entity] components;
}
