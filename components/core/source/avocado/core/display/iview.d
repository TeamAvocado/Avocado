module avocado.core.display.iview;

import avocado.core.display.irenderer;

/// Interface for views
interface IView {
	/// Registers a renderer to this view
	final void register(IRenderer renderer) {
		renderer.register(this);
	}

	/// Create a context for a renderer
	void createContext(IRenderer renderer);

	/// Activates the context for rendering
	void activateContext(IRenderer renderer);

	/// Get the window handle or similar
	void* getHandle();

	/// Handles events and might display things.
	bool update();

	/// Identifier for this view
	@property string type() const;
}
