module avocado.core.display.imesh;

import avocado.core.display.irenderer;

/// Representation of a 3d model
interface IMesh {
	/// Converts the buffers to a renderable mesh
	IMesh generate();
	/// Draws the mesh onto the renderer
	void draw(IRenderer renderer);
}
