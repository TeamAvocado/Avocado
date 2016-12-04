module avocado.core.display.nullview;

import avocado.core.display.iview;
import avocado.core.display.irenderer;
import avocado.core.event;

class NullView : IView {
	this(string) {

	}
	/// Create a context for a renderer
	void createContext(IRenderer renderer) {
	}

	/// Activates the context for rendering
	void activateContext(IRenderer renderer) {
	}

	/// Get the window handle or similar
	void* getHandle() {
		return null;
	}

	/// Handles events and might display things.
	bool update() {
		return !_quit;
	}

	/// Closes the window and invalidates it.
	void close() @nogc {
		_quit = true;
	}

	/// Identifier for this view
	@property string type() const {
		return "NullView";
	}

	/// Gets called when the window got resized
	/// Returns: an Event with width and height as parameters
	ref Event!(int, int) onResized() @property {
		return _onResized;
	}

	/// Returns the width of this view
	int width() @property {
		return 0;
	}

	/// Returns the height of this view
	int height() @property {
		return 0;
	}

private:
	bool _quit;
	Event!(int, int) _onResized;
}
