module avocado.core.display.irenderer;

import avocado.core.util;
import avocado.core.display.iview;
import avocado.core.display.itexture;
import avocado.core.display.ishader;
import avocado.core.display.imesh;

/// Renderer with functions every renderer must have
interface IRenderer {
	/// Registers the view with this renderer
	void register(IView view);

	/// Prepares rendering for this view
	void begin(IView view);

	/// Ends rendering for this view
	void end(IView view);

	/// Identifier for this renderer
	@property string type() const;
}

/// Renderer with generic function every renderer should have
interface IGenericRenderer : IRenderer {
	/// Clears the screen with the previously set color
	void clear();
	/// Sets the clear color
	@property void clearColor(vec4 color);
	/// Binds a shader for rendering and automatically set projection & modelview uniforms
	void bind(IShader shader);
	/// Binds a shader for rendering and set uniforms manually
	void bind(IShader shader, void delegate(IShader) applyShaderFunction);
	/// Projection matrix for projecting vertices onto the target
	ref MatrixStack!mat4 projection() @property;
	/// Modelview matrix for transformations
	ref MatrixStack!mat4 modelview() @property;
	/// Resizes the viewport
	void resize(int width, int height);
}

/// Renderer containing functions for 2D only rendering
interface I2DRenderer : IGenericRenderer {
	/// Fills a Rectangle with position and size to a solid color
	void fillRectangle(vec4 rect, vec4 color = vec4(1, 1, 1, 1));
	/// Draws a Rectangle with position, size and texture
	void drawRectangle(ITexture texture, vec4 rect, vec4 color = vec4(1, 1, 1, 1));
	/// Draws a Rectangle with the source rectangle as texture rectangle
	void drawRectangle(ITexture texture, vec4 source, vec4 destination, vec4 color);
}

/// Renderer containing functions for 3D only rendering
interface I3DRenderer : IGenericRenderer {
	/// Draws a mesh
	void drawMesh(IMesh mesh);
}

/// Renderer containing functions for combining 2D and 3D rendering
interface ICommonRenderer : I2DRenderer, I3DRenderer {
	/// Prepares rendering for 2D
	void bind2D();
	/// Prepares rendering for 3D
	void bind3D();
}
