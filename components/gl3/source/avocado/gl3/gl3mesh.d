module avocado.gl3.gl3mesh;

import avocado.core.display.imesh;
import avocado.core.display.irenderer;
import avocado.core.util;
import avocado.gl3;

import std.typecons;
import std.conv;
import std.meta;

/// Buffer type for elements
enum BufferType {
	/// Generic data element
	Element,
	/// Element is an index. There can only be one index buffer per mesh!
	Index
}

/// Primitive type for rendering
enum PrimitiveType {
	/// Each vertex will be rendered as separate point
	Points = GL_POINTS,
	/// Lines going through each vertex
	LineStrip = GL_LINE_STRIP,
	/// Lines going through each vertex and from the end to the start
	LineLoop = GL_LINE_LOOP,
	/// A line for every vertex pair. By default every odd vertex is a line beginning and every even vertex is a line ending.
	Lines = GL_LINES,
	/// Additional vertices for geometry shaders
	LineStripAdjacency = GL_LINE_STRIP_ADJACENCY,
	/// Additional vertices for geometry shaders
	LinesAdjacency = GL_LINES_ADJACENCY,
	/// Generates multiple connected triangles. By default every additional vertex will create a new triangle with the previous 2 ones.
	TriangleStrip = GL_TRIANGLE_STRIP,
	/// Generates multiple connected triangles. By default the first vertex is the vertex every other vertex will connect to.
	TriangleFan = GL_TRIANGLE_FAN,
	/// A triangle for every 3 vertices. This is the default.
	Triangles = GL_TRIANGLES,
	/// Additional vertices for geometry shaders
	TriangleStripAdjacency = GL_TRIANGLE_STRIP_ADJACENCY,
	/// Additional vertices for geometry shaders
	TrianglesAdjacency = GL_TRIANGLES_ADJACENCY,
	/// Can only be used when Tessellation is active. It is a primitive with a
	/// user-defined number of vertices, which is then tessellated based on the
	/// control and evaluation shaders into regular points, lines, or triangles,
	/// depending on the TES's settings.
	Patches = GL_PATCHES
}

template GLTypeForType(T) {
	static if (is(T == byte))
		enum GLTypeForType = GL_BYTE;
	else static if (is(T == ubyte))
		enum GLTypeForType = GL_UNSIGNED_BYTE;
	else static if (is(T == short))
		enum GLTypeForType = GL_SHORT;
	else static if (is(T == ushort))
		enum GLTypeForType = GL_UNSIGNED_SHORT;
	else static if (is(T == int))
		enum GLTypeForType = GL_INT;
	else static if (is(T == uint))
		enum GLTypeForType = GL_UNSIGNED_INT;
	else static if (is(T == float))
		enum GLTypeForType = GL_FLOAT;
	else
		static assert(0, "No GLType for Type " ~ T.stringof);
}

// TODO: Alternative template construction using a struct
struct BufferElement(string name, int len, T = float, bool normalized = false, BufferType type = BufferType.Element, bool stream = false) {
	alias ElementType = T;
	static if (len == 1)
		alias DataType = T;
	else
		alias DataType = Vector!(T, len);
	alias Name = name;
	alias Type = type;
	alias GLType = GLTypeForType!T;
	alias Length = len;
	alias Stream = stream;

	DataType data;

	this(DataType value) {
		data = value;
	}
}

private mixin template GenerateBufferFunction(Elem) {
	mixin("private Elem.DataType[] data" ~ Elem.Name ~ ";");
	mixin("public typeof(this) add" ~ Elem.Name ~ "(Elem.DataType point) { data" ~ Elem.Name ~ " ~= point; return this; }");
	mixin("public typeof(this) add" ~ Elem.Name ~ "Array(Elem.DataType[] data) { data" ~ Elem.Name ~ " ~= data; return this; }");
	static if (Elem.Stream) {
		mixin("private int vbo" ~ Elem.Name ~ ";");
		mixin("private int maxlen" ~ Elem.Name ~ ";");
		mixin("public typeof(this) reserve" ~ Elem.Name ~ "(int capacity) {maxlen" ~ Elem.Name ~ " = capacity; return this; }");
		mixin("public typeof(this) fill" ~ Elem.Name ~ "(Elem.DataType[] data) {
			glBindBuffer(GL_ARRAY_BUFFER, vbo" ~ Elem.Name
			~ ");
			glBufferData(GL_ARRAY_BUFFER, Elem.DataType.sizeof * Elem.Length * maxlen" ~ Elem.Name ~ ", null, GL_STREAM_DRAW);
			glBufferSubData(GL_ARRAY_BUFFER, 0, cast(int) (Elem.DataType.sizeof * Elem.Length * data.length), data.ptr);
			return this;
		}");
	}
}

private mixin template GenerateBufferFunctions(Elem, T...) {
	mixin GenerateBufferFunction!Elem;
	static if (T.length > 0)
		mixin GenerateBufferFunctions!T;
}

private mixin template BufferGLImpl(bool firstIndex, int i, S, T...) {
	static if (S.Type == BufferType.Element) {
		mixin("alias _mixin_step" ~ to!string(i) ~ " = _mixin_gen_;");

		private void _mixin_gen_() {
			import std.traits : isIntegral;

			glBindBuffer(GL_ARRAY_BUFFER, _vbo[i]);
			enforceGLErrors();
			auto data = mixin("data" ~ S.Name);
			static if (S.Stream) {
				auto maxlen = mixin("maxlen" ~ S.Name);
				assert(maxlen != 0, "Need a maximum length for streaming elements. (call reserve" ~ S.Name ~ "(int) before generating)");
				glBufferData(GL_ARRAY_BUFFER, S.DataType.sizeof * maxlen, null, GL_STREAM_DRAW);
				enforceGLErrors();
			} else {
				glBufferData(GL_ARRAY_BUFFER, S.DataType.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
				enforceGLErrors();
				if (_vertexLength != 0)
					assert(_vertexLength == data.length, "All vertex elements must be of same length!");
				_vertexLength = cast(GLsizei)data.length;
			}
			static if (isIntegral!(S.ElementType))
				glVertexAttribIPointer(cast(uint)i, S.Length, S.GLType, 0, null);
			else
				glVertexAttribPointer(cast(uint)i, S.Length, S.GLType, 0u, 0, null);
			enforceGLErrors();
			glEnableVertexAttribArray(cast(int)i);
			enforceGLErrors();
			static if (S.Stream)
				mixin("vbo" ~ S.Name ~ " = _vbo[i];");
		}

		static if (T.length > 0)
			mixin BufferGLImpl!(firstIndex, i + 1, T);
	} else static if (S.Type == BufferType.Index) {
		static assert(firstIndex, "Can only have 1 index element!");

		mixin("alias _mixin_step" ~ to!string(i) ~ " = _mixin_gen_;");

		private void _mixin_gen_() {
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vbo[i]);
			auto data = mixin("data" ~ S.Name);
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, S.DataType.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
			_indexLength = cast(GLsizei)data.length;
			_indexType = S.GLType;
		}

		static if (T.length > 0)
			mixin BufferGLImpl!(false, i + 1, T);
	} else
		static assert(0);
}

private template ForeachCall(string prefix, int index, int length) {
	static if (index >= length)
		enum ForeachCall = "";
	else
		enum ForeachCall = prefix ~ to!string(index) ~ "(); " ~ ForeachCall!(prefix, index + 1, length);
}

private template InstanceAttribDivisor(int index, S, T...) {
	static if (T.length == 0)
		enum InstanceAttribDivisor = "glVertexAttribDivisor(" ~ to!string(index) ~ ", " ~ (S.Stream ? "1" : "0") ~ ");";
	else
		enum InstanceAttribDivisor = "glVertexAttribDivisor(" ~ to!string(index) ~ ", " ~ (S.Stream ? "1" : "0") ~ "); " ~ InstanceAttribDivisor!(
				index + 1, T);
}

private template HasIndex(S, T...) {
	static if (S.Type == BufferType.Element) {
		static if (T.length > 0)
			enum HasIndex = HasIndex!(T);
		else
			enum HasIndex = false;
	} else static if (S.Type == BufferType.Index) {
		enum HasIndex = true;
	} else {
		static if (T.length > 0)
			enum HasIndex = HasIndex!(T);
		else
			enum HasIndex = false;
	}
}

/// Representation and generator for an OpenGL VAO
class GL3Mesh(T...) : IMesh {
	static assert(T.length > 0, "Need at least one element in GL3Mesh");
public:
	alias Elements = T;

	~this() {
		if (_generated) {
			glDeleteBuffers(T.length, _vbo);
			glDeleteVertexArrays(1, &_vao);
			_indexLength = 0;
			_generated = false;
		}
	}

	/// Converts the buffers to a renderable mesh
	IMesh generate() {
		assert(!_generated, "Can't regenerate mesh!");
		enforceGLErrors();

		_vao = 0;
		glGenVertexArrays(1, &_vao);
		glBindVertexArray(_vao);

		_vbo = new uint[T.length].ptr;

		glGenBuffers(T.length, _vbo);

		mixin(ForeachCall!("_mixin_step", 0, T.length));

		glBindVertexArray(0);

		_generated = true;
		return this;
	}

	mixin GenerateBufferFunctions!T;
	mixin BufferGLImpl!(true, 0, T);

	void draw(IRenderer renderer) {
		assert(_generated, "Call generate() before drawing!");
		assert(cast(GL3Renderer)renderer, "Renderer must be a GL3Renderer!");

		glBindVertexArray(_vao);
		static if (HasIndex!T)
			glDrawElements(_primitiveType, _indexLength, _indexType, null);
		else
			glDrawArrays(_primitiveType, 0, _vertexLength);
	}

	void drawInstanced(IRenderer renderer, int count) {
		assert(_generated, "Call generate() before drawing!");
		assert(cast(GL3Renderer)renderer, "Renderer must be a GL3Renderer!");

		glBindVertexArray(_vao);
		enforceGLErrors();
		//pragma(msg, T.stringof ~ ": " ~ InstanceAttribDivisor!(0, T));
		mixin(InstanceAttribDivisor!(0, T));
		enforceGLErrors();
		static if (HasIndex!T)
			glDrawElementsInstanced(_primitiveType, _indexLength, _indexType, null, count);
		else
			glDrawArraysInstanced(_primitiveType, 0, _vertexLength, count);
		enforceGLErrors();
	}

	@property ref auto primitiveType() {
		return _primitiveType;
	}

private:
	PrimitiveType _primitiveType = PrimitiveType.Triangles;
	uint _vao;
	uint* _vbo;
	GLsizei _indexLength, _vertexLength;
	GLenum _indexType;
	bool _generated = false;
}

alias IndexElement = BufferElement!("Index", 1, uint, false, BufferType.Index);

alias GL3MeshCommon = GL3MeshIndexPositionTextureNormal;
alias GL3ShapeCommon = GL3ShapePositionTexture;

alias PositionElement = BufferElement!("Position", 3);
alias ColorElement = BufferElement!("Color", 3);
alias ColorAlphaElement = BufferElement!("Color", 4);
alias TexCoordElement = BufferElement!("TexCoord", 2);
alias TexCoordElement3D = BufferElement!("TexCoord", 3);
alias NormalElement = BufferElement!("Normal", 3);
alias BinormalElement = BufferElement!("Binormal", 3);
alias TangentElement = BufferElement!("Tangent", 3);

alias GL3MeshIndexPositionTextureNormal = GL3Mesh!(IndexElement, PositionElement, TexCoordElement, NormalElement);
alias GL3MeshIndexPositionColorTextureNormal = GL3Mesh!(IndexElement, PositionElement, ColorElement, TexCoordElement, NormalElement);
alias GL3MeshIndexPositionColorAlphaTextureNormal = GL3Mesh!(IndexElement, PositionElement, ColorAlphaElement,
	TexCoordElement, NormalElement);
alias GL3MeshIndexPositionColorTexture = GL3Mesh!(IndexElement, PositionElement, ColorElement, TexCoordElement);
alias GL3MeshIndexPositionColorAlphaTexture = GL3Mesh!(IndexElement, PositionElement, ColorAlphaElement, TexCoordElement);
alias GL3MeshIndexPositionTexture = GL3Mesh!(IndexElement, PositionElement, TexCoordElement);
alias GL3MeshIndexPositionColor = GL3Mesh!(IndexElement, PositionElement, ColorElement);
alias GL3MeshIndexPositionColorAlpha = GL3Mesh!(IndexElement, PositionElement, ColorAlphaElement);

alias PositionElement2D = BufferElement!("Position", 2);

alias GL3ShapePosition = GL3Mesh!(PositionElement2D);
alias GL3ShapePositionTexture = GL3Mesh!(PositionElement2D, TexCoordElement);
