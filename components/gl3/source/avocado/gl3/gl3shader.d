module avocado.gl3.gl3shader;

import avocado.core.display.irenderer;
import avocado.core.display.ishader;
import avocado.core.util;
import avocado.gl3;

import std.string;
import std.regex;
import std.conv;

/// Shader Type for the GLShaderUnit
enum ShaderType {
	/// Only available in OpenGL 4.3 or higher
	Compute = GL_COMPUTE_SHADER,
	/// Tesselation control shader 
	TessControl = GL_TESS_CONTROL_SHADER,
	/// Tesselation evauluation shader
	TessEvaluation = GL_TESS_EVALUATION_SHADER,
	/// Geometry shader
	Geometry = GL_GEOMETRY_SHADER,
	/// Vertex shader
	Vertex = GL_VERTEX_SHADER,
	/// Fragment shader
	Fragment = GL_FRAGMENT_SHADER
}

enum uniformRegex = ctRegex!`uniform\s+[a-zA-Z_][0-9a-zA-Z_]*\s+([a-zA-Z_][0-9a-zA-Z_]*)(?:\[.*?\])?\s*(?:=.+?)?;`;

/// Compiled shader part (vertex, fragment, etc.)
/// Checks for duplicate shaders in debug mode
class GLShaderUnit {
public:
	/// Creates & compiles a shader
	/// Checks for duplicates using a md5 checksum in debug mode
	this(ShaderType type, string content, bool scanUniforms = true) {
		debug {
			import std.algorithm;
			import std.digest.md;

			auto hash = md5Of(content);
			assert(!hashSums.canFind(hash), "Attempted to create duplicate shader unit: " ~ content);
			hashSums ~= hash;
			_content = content;
		}
		_id = glCreateShader(type);
		if (_id == 0) {
			_success = false;
			_msg = "Error in glCreateShader";
			return;
		}
		immutable len = cast(immutable(GLint))content.length;
		glShaderSource(_id, 1, [content.ptr].ptr, &len);
		glCompileShader(_id);
		int success = 0;
		glGetShaderiv(_id, GL_COMPILE_STATUS, &success);
		if (success == 0) {
			int logSize = 0;
			glGetShaderiv(_id, GL_INFO_LOG_LENGTH, &logSize);

			char* log = new char[logSize].ptr;
			glGetShaderInfoLog(_id, logSize, &logSize, &log[0]);

			_msg = "Error in glCompileShader for " ~ type.to!string ~ "Shader:\n" ~ log[0 .. logSize].idup;
			_success = false;
			return;
		}
		if (scanUniforms)
			foreach (match; matchAll(content, uniformRegex))
				_uniforms ~= match[1];
	}

	/// Returns the error message (if any)
	string error() @property {
		return _msg;
	}

	/// Returns whether or not the shader was compiled successfully
	auto success() @property {
		return _success;
	}

	/// Returns the shader id
	auto id() @property {
		return _id;
	}

	/// Returns the generated uniform values (if enabled)
	auto uniforms() @property {
		return _uniforms;
	}

	/// Returns the shader code (debug only)
	auto content() @property {
		return _content;
	}

private:
	debug static ubyte[16][] hashSums;
	uint _id;
	bool _success = true;
	string[] _uniforms;
	string _msg, _content;
}

class GL3ShaderProgram : IShader {
public:
	this() {
		_program = glCreateProgram();
	}

	this(IRenderer renderer, GLShaderUnit[] units...) {
		this();
		foreach (unit; units)
			attach(unit);
		create(renderer);
		foreach (unit; units)
			register(unit.uniforms);
	}

	GL3ShaderProgram attach(GLShaderUnit shader) {
		assert(shader.success, shader.error);
		if (shader.success) {
			glAttachShader(_program, shader.id);
		}
		return this;
	}

	void create(IRenderer renderer) {
		assert(cast(GL3Renderer)renderer);
		glLinkProgram(_program);
		bind(renderer);
	}

	void bind(IRenderer renderer) {
		assert(cast(GL3Renderer)renderer);
		glUseProgram(_program);
	}

	void set(T)(string uniform, T value) {
		import std.traits;

		assert(uniform in _uniforms, "Uniform '" ~ uniform ~ "' does not exist. Did you register it?");
		enforceGLErrors("An error occured previously!\n");

		static if (isArray!T) {
			alias U = typeof(value[0]);
			assert(value.length < int.max, "Too many values for a shader");
			static if (is(U == int))
				glUniform1iv(_uniforms[uniform], cast(int)value.length, value.ptr);
			else static if (is(U == float))
				glUniform1fv(_uniforms[uniform], cast(int)value.length, value.ptr);
			else static if (is(U == vec2))
				glUniform2fv(_uniforms[uniform], cast(int)value.length, value.ptr);
			else static if (is(U == vec3))
				glUniform3fv(_uniforms[uniform], cast(int)value.length, value.ptr);
			else static if (is(U == vec4))
				glUniform4fv(_uniforms[uniform], cast(int)value.length, value.ptr);
			else static if (is(U == mat2))
				glUniformMatrix2fv(_uniforms[uniform], cast(int)value.length, 1, value.ptr);
			else static if (is(U == mat3))
				glUniformMatrix3fv(_uniforms[uniform], cast(int)value.length, 1, value.ptr);
			else static if (is(U == mat4))
				glUniformMatrix4fv(_uniforms[uniform], cast(int)value.length, 1, value.ptr);
			else
				static assert(0, "Invalid shader argument type: " ~ T.stringof);
		} else {
			static if (is(T == int))
				glUniform1i(_uniforms[uniform], value);
			else static if (is(T == float))
				glUniform1f(_uniforms[uniform], value);
			else static if (is(T == vec2))
				glUniform2fv(_uniforms[uniform], 1, value.value_ptr);
			else static if (is(T == vec3))
				glUniform3fv(_uniforms[uniform], 1, value.value_ptr);
			else static if (is(T == vec4))
				glUniform4fv(_uniforms[uniform], 1, value.value_ptr);
			else static if (is(T == mat2))
				glUniformMatrix2fv(_uniforms[uniform], 1, 1, value.value_ptr);
			else static if (is(T == mat3))
				glUniformMatrix3fv(_uniforms[uniform], 1, 1, value.value_ptr);
			else static if (is(T == mat4))
				glUniformMatrix4fv(_uniforms[uniform], 1, 1, value.value_ptr);
			else
				static assert(0, "Invalid shader argument type: " ~ T.stringof);
		}
		enforceGLErrors("Error assigning uniform value. Please ensure this shader is currently bound. (for " ~ uniform ~ ")\n");
	}

	void registerUniform(string uniform) {
		if (uniform in _uniforms)
			return;
		immutable location = glGetUniformLocation(_program, uniform.toStringz);
		assert(location != -1, "Uniform '" ~ uniform ~ "' does not exist in shader program or is reserved!");
		_uniforms[uniform] = location;
	}

	void register(string[] uniforms) {
		foreach (uniform; uniforms)
			registerUniform(uniform);
	}

	auto id() @property {
		return _program;
	}

private:
	int[string] _uniforms;
	uint _program;
}
