module avocado.core.display.iview;

import avocado.core.display.irenderer;
import avocado.core.event;

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

	/// Gets called when the window got resized
	/// Returns: an Event with width and height as parameters
	ref Event!(int, int) onResized() @property;

	/// Returns the width of this view
	int width() @property;

	/// Returns the height of this view
	int height() @property;
}
