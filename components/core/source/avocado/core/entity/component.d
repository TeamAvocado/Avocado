module avocado.core.entity.component;

///
mixin template ComponentBase(T = void, int startingAmount = 8) {
	import std.conv : to;

	public static auto add(arg...)(Entity entity, arg args) {
		static if (is(T == void))
			return components[entity] = new typeof(this)(args);
		else
			return components[entity] = new T(args);
	}

	public static auto get(Entity entity) {
		auto p = entity in components;
		return p ? *p : null;
	}

	static if (is(T == void))
		private static typeof(this)*[Entity] components;
	else
		private static T*[Entity] components;
}
