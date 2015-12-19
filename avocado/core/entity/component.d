module avocado.core.entity.component;

///
template ComponentBase(T, int startingAmount = 8) {
    import std.conv : to;

    //dfmt off
    const char[] ComponentBase = "
    public static:
        auto add(arg...)(Entity entity, arg args) {
            return components[entity] = new "~T.stringof~"(args);
        }

        auto get(Entity entity) {
            auto p = entity in components;
            return p ? *p : null;
        }

    private static:
        "~T.stringof~"*[Entity] components;
    ";
    //dfmt on
}
