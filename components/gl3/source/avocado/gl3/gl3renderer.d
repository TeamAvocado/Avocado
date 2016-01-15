module avocado.gl3.gl3renderer;

import avocado.gl3;
import avocado.gl3.gltexture;
import avocado.gl3.gl3mesh;
import avocado.gl3.gl3shader;

import derelict.sdl2.sdl;

import avocado.core.display.irenderer;
import avocado.core.display.iview;
import avocado.core.display.imesh;
import avocado.core.display.ishader;
import avocado.core.display.itexture;
import avocado.core.util;

/// Depth test functions
enum DepthFunc {
	Never = GL_NEVER,
	Less = GL_LESS,
	Equal = GL_EQUAL,
	LEqual = GL_LEQUAL,
	Greater = GL_GREATER,
	NotEqual = GL_NOTEQUAL,
	GEqual = GL_GEQUAL,
	Always = GL_ALWAYS,
}

/// GUI Initialization arguments
struct GLGUIArguments {
	/// If information should be compiled
	bool enableGUI;
	/// Width of the projection matrix (used for positioning)
	int virtualWidth;
	/// Height of the projection matrix (used for positioning)
	int virtualHeight;
	/// If true, the projection matrix size won't change on resize
	bool lockSize;
	/// Custom vertex shader for GUI
	string vertexShader = `#version 330
layout(location = 0) in vec2 in_position;

uniform mat4 modelview;
uniform mat4 projection;
uniform vec4 sourceRect;
out vec2 texCoord;

void main()
{
	gl_Position = projection * modelview * vec4(in_position.xy, 0, 1);
	texCoord = in_position.xy * sourceRect.zw + sourceRect.xy;
}`;
	/// Custom fragment shader for GUI
	string fragmentShader = `#version 330
uniform sampler2D tex;
uniform vec4 color;
in vec2 texCoord;

layout(location = 0) out vec4 out_frag_color;

void main()
{
	out_frag_color = texture(tex, texCoord) * color;
}`;
	/// Custom shader uniforms
	string[] shaderUniforms = ["modelview", "projection", "sourceRect", "tex", "color"];
}

/// Renderer using OpenGL3.2. Supported view types: SDL2
class GL3Renderer : ICommonRenderer {
public:
	/// Params:
	/// 	gui: Parameters for gui rendering
	this(GLGUIArguments gui = GLGUIArguments(true, 800, 480, false)) {
		if (gui.enableGUI)
			_gui = gui;
	}

	// inherited
public:

	/// Registers the view with this renderer
	void register(IView view) {
		assert(view.type == "SDL2", "Unsupported window type for GL3Renderer: " ~ view.type);
		DerelictGL3.load();
		view.createContext(this);
		DerelictGL3.reload();
		view.activateContext(this);

		postInit();
	}

	/// Prepares rendering for this view
	void begin(IView view) {
		assert(view.type == "SDL2", "Unsupported window type for GL3Renderer: " ~ view.type);
		view.activateContext(this);
	}

	/// Ends rendering for this view
	void end(IView view) {
		assert(view.type == "SDL2", "Unsupported window type for GL3Renderer: " ~ view.type);
		SDL_GL_SwapWindow(cast(SDL_Window*)view.getHandle);
	}

	/// Identifier for this renderer
	@property string type() const {
		return "GL3";
	}

	/// Clears the screen with the previously set color
	void clear() {
		glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	}

	/// Sets the clear color
	@property void clearColor(vec4 color) {
		glClearColor(color.r, color.g, color.b, color.a);
	}

	/// Draws a Rectangle with position, size and texture
	void drawRectangle(ITexture texture, vec4 rect, vec4 color = vec4(1, 1, 1, 1)) {
		drawRectangle(texture, vec4(0, 0, 1, 1), rect, color);
	}

	/// Draws a Rectangle with the source rectangle as texture rectangle
	void drawRectangle(ITexture texture, vec4 source, vec4 destination, vec4 color) {
		modelview.push();
		modelview.top = mat4.translation(destination.x, destination.y, 0) * mat4.scaling(destination.z, destination.w, 1);
		bind(_guiShader);
		texture.bind(this, 0);
		_guiShader.set("sourceRect", source);
		_guiShader.set("color", color);
		_unitRectangle.draw(this);
		modelview.pop();
	}

	/// Draws a mesh
	void drawMesh(IMesh mesh) {
		mesh.draw(this);
	}

	/// Prepares rendering for 2D
	void bind2D() {
		projection.push();
		projection.top = _guiProjection;
		disableDepthTest();
	}

	/// Prepares rendering for 3D
	void bind3D() {
		projection.pop();
		enableDepthTest();
		//enforceGLErrors();
	}

	/// Projection matrix stack for projecting vertices onto the target. Has a depth of 2.
	ref MatrixStack!mat4 projection() @property {
		return _projection;
	}

	/// Modelview matrix stack for transformations. Has a depth of 16.
	ref MatrixStack!mat4 modelview() @property {
		return _modelview;
	}

	/// Binds a shader for rendering and automatically set projection & modelview uniforms
	void bind(IShader shader) {
		(cast(GL3ShaderProgram)shader).bind(this);
		(cast(GL3ShaderProgram)shader).set("projection", _projection.top);
		(cast(GL3ShaderProgram)shader).set("modelview", _modelview.top);
	}

	/// Binds a shader for rendering and set uniforms manually
	void bind(IShader shader, void delegate(IShader) applyShaderVariables) {
		shader.bind(this);
		applyShaderVariables(shader);
	}

	/// Resizes the viewport and the gui projection matrix
	void resize(int width, int height) {
		glViewport(0, 0, width, height);
		if (_gui.enableGUI && !_gui.lockSize)
			_guiProjection = ortho2D(width, height, -1, 1);
	}

	// OpenGL specific
public:
	/// Enables depth test and sets function for it
	void setupDepthTest(DepthFunc func, float defaultDepth = 1.0f) {
		enableDepthTest();
		glDepthFunc(func);
		glClearDepth(defaultDepth);
	}

	/// Enables depth test
	void enableDepthTest() {
		glEnable(GL_DEPTH_TEST);
	}

	/// Disables depth test
	void disableDepthTest() {
		glDisable(GL_DEPTH_TEST);
	}

private:

	void postInit() {
		if (_gui.enableGUI) {
			_guiShader = new GL3ShaderProgram();
			_guiShader.attach(new GLShaderUnit(ShaderType.Vertex, _gui.vertexShader));
			_guiShader.attach(new GLShaderUnit(ShaderType.Fragment, _gui.fragmentShader));
			_guiShader.create(this);
			_guiShader.register(_gui.shaderUniforms);
			_guiShader.set("tex", 0);

			_guiProjection = ortho2D(_gui.virtualWidth, _gui.virtualHeight, -1, 1);

			_unitRectangle = new GL3ShapePosition();
			_unitRectangle.addPositionArray([vec2(0, 0), vec2(1, 0), vec2(1, 1), vec2(1, 1), vec2(0, 0), vec2(0, 1)]);
			_unitRectangle.generate();
		}
	}

	GLGUIArguments _gui = GLGUIArguments(false, 0, 0, false, "", "", []);
	GL3ShapePosition _unitRectangle;
	GL3ShaderProgram _guiShader;
	mat4 _guiProjection;
	MatrixStack!mat4 _modelview = 16;
	MatrixStack!mat4 _projection = 2;
}
