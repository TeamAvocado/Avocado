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

	import asdf : Asdf, serializeToAsdf, deserializeValue;
	import painlesstraits : allPublicFields, hasAnnotation;
	import gl3n.linalg : Vector, Matrix;

	void setAttribute(string name, Asdf value) {
		foreach (memberName; allPublicFields!(typeof(this))) {
			static if (!hasAnnotation!(mixin("this." ~ memberName), ignoreLevelJson)) {
				alias member = Identity!(mixin("this." ~ memberName));
				alias MemberType = typeof(member);
				if (name == memberName) {
					static if (is(MemberType : Vector!(T, dimension), T, int dimension)) {
						deserializeValue(value, member.vector);
						return;
					} else static if (is(MemberType : Matrix!(T, rows, cols), T, int rows, int cols)) {
						deserializeValue(value, member.matrix);
						return;
					} else static if (__traits(compiles, deserializeValue(value, member))) {
						deserializeValue(value, member);
						return;
					} else
						throw new Exception("Attribute '" ~ name ~ "' of type " ~ MemberType.stringof ~ " is not deserializable from json");
				}
			}
		}
	}

	Asdf getAttribute(string name) {
		foreach (memberName; allPublicFields!(typeof(this))) {
			static if (!hasAnnotation!(mixin("this." ~ memberName), ignoreLevelJson)) {
				alias member = Identity!(mixin("this." ~ memberName));
				alias MemberType = typeof(member);
				if (name == memberName) {
					static if (is(MemberType : Vector!(T, dimension), T, int dimension))
						return member.vector.serializeToAsdf;
					else static if (is(MemberType : Matrix!(T, rows, cols), T, int rows, int cols))
						return member.matrix.serializeToAsdf;
					else static if (__traits(compiles, member.serializeToAsdf))
						return member.serializeToAsdf;
					else
						throw new Exception("Attribute '" ~ name ~ "' of type " ~ MemberType.stringof ~ " is not serializable to json");
				}
			}
		}
		return serializeToAsdf(null);
	}

private:
	alias ThisType = typeof(this);
	private static ThisType*[Entity] components;
}
