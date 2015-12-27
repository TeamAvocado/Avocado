module avocado.gl3.gl3renderer;

import avocado.gl3;
import avocado.gl3.gltexture;
import avocado.gl3.gl3mesh;

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

/// Renderer using OpenGL3.2. Supported view types: SDL2
class GL3Renderer : ICommonRenderer {
	// inherited
public:
	/// Registers the view with this renderer
	void register(IView view) {
		if (view.type == "SDL2") {
			DerelictGL3.load();
			view.createContext(this);
			DerelictGL3.reload();
			view.activateContext(this);

			postInit();
		} else
			assert(0, "Unsupported window type for GL3Renderer: " ~ view.type);
	}

	/// Prepares rendering for this view
	void begin(IView view) {
		if (view.type == "SDL2") {
			view.activateContext(this);
		} else
			assert(0, "Unsupported window type for GL3Renderer: " ~ view.type);
	}

	/// Ends rendering for this view
	void end(IView view) {
		if (view.type == "SDL2") {
			SDL_GL_SwapWindow(cast(SDL_Window*)view.getHandle);
		} else
			assert(0, "Unsupported window type for GL3Renderer: " ~ view.type);
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
	void drawRectangle(ITexture texture, vec4 rect) {
	}

	/// Draws a Rectangle with the source rectangle as texture rectangle
	void drawRectangle(ITexture texture, vec4 source, vec4 destination) {
	}

	/// Draws a mesh
	void drawMesh(IMesh mesh) {
		mesh.draw(this);
	}

	/// Prepares rendering for 2D
	void bind2D() {
		disableDepthTest();
	}

	/// Prepares rendering for 3D
	void bind3D() {
		enableDepthTest();
	}

	// OpenGL specific
public:
	void setupDepthTest(DepthFunc func, float defaultDepth = 1.0f) {
		enableDepthTest();
		glDepthFunc(func);
		glClearDepth(defaultDepth);
	}

	void enableDepthTest() {
		glEnable(GL_DEPTH_TEST);
	}

	void disableDepthTest() {
		glDisable(GL_DEPTH_TEST);
	}

private:
	void postInit() {
	}
}
