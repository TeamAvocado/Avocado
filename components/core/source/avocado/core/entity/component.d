module avocado.core.entity.component;

/// UDA to not include this member in level deserialization
enum ignoreLevelJson;

public alias Identity(alias A) = A;

///
mixin template ComponentBase() {
public:
	static auto add(Args...)(Entity entity, Args args) {
		return components[entity] = new ThisType(args);
	}

	static auto get(Entity entity) {
		auto p = entity in components;
		return p ? *p : null;
	}

	static void set(Entity entity, ThisType* com) {
		components[entity] = com;
	}

	static void remove(Entity entity) {
		components.remove(entity);
	}

	@property static ThisType*[Entity] entities() {
		return ThisType.components;
	}

private:
	alias ThisType = typeof(this);
	static ThisType*[Entity] components;
}
