module avocado.gl3.gl3shader;

import avocado.core.display.irenderer;
import avocado.core.display.ishader;
import avocado.core.util;
import avocado.gl3;

import std.string;

enum ShaderType {
    /// Only available in OpenGL 4.3 or higher
    Compute = GL_COMPUTE_SHADER,
    TessControl = GL_TESS_CONTROL_SHADER,
    TessEvaluation = GL_TESS_EVALUATION_SHADER,
    Geometry = GL_GEOMETRY_SHADER,
    Vertex = GL_VERTEX_SHADER,
    Fragment = GL_FRAGMENT_SHADER
}

class GLShaderUnit {
public:
    this(ShaderType type, string content) {
        _id = glCreateShader(type);
        if (_id == 0) {
            _success = false;
            _msg = "Error in glCreateShader";
            return;
        }
        immutable len = cast(immutable(GLint)) content.length;
        glShaderSource(_id, 1, [content.ptr].ptr, &len);
        glCompileShader(_id);
        int success = 0;
        glGetShaderiv(_id, GL_COMPILE_STATUS, &success);
        if (success == 0) {
            int logSize = 0;
            glGetShaderiv(_id, GL_INFO_LOG_LENGTH, &logSize);

            char* log = new char[logSize].ptr;
            glGetShaderInfoLog(_id, logSize, &logSize, &log[0]);

            _msg = "Error in glCompileShader:\n" ~ log[0 .. logSize].idup;
            _success = false;
            return;
        }
    }

    string error() @property {
        return _msg;
    }

    auto success() @property {
        return _success;
    }

    auto id() @property {
        return _id;
    }

private:
    uint _id;
    bool _success = true;
    string _msg;
}

class GL3ShaderProgram : IShader {
public:
    this() {
        _program = glCreateProgram();
    }

    GL3ShaderProgram attach(GLShaderUnit shader) {
        assert(shader.success, shader.error);
        if (shader.success) {
            glAttachShader(_program, shader.id);
        }
        return this;
    }

    void create(IRenderer renderer) {
        assert(cast(GL3Renderer) renderer);
        glLinkProgram(_program);
        bind(renderer);
    }

    void bind(IRenderer renderer) {
        assert(cast(GL3Renderer) renderer);
        glUseProgram(_program);
    }

    void set(T)(string uniform, T value) {
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
    
    void registerUniform(string uniform) {
        _uniforms[uniform] = glGetUniformLocation(_program, uniform.toStringz);
    }

    auto id() @property {
        return _program;
    }

private:
    int[string] _uniforms;
    uint _program;
}
