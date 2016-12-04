module avocado.core.display.nullrenderer;

import avocado.core.display.iview;
import avocado.core.display.irenderer;

class NullRenderer : IRenderer {
	/// Registers the view with this renderer
	void register(IView view) {
	}

	/// Prepares rendering for this view
	void begin(IView view) {
	}

	/// Ends rendering for this view
	void end(IView view) {
	}

	/// Identifier for this renderer
	@property string type() const {
		return "NullRenderer";
	}
}
