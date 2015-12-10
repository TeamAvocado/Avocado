module avocado.core.display.irenderer;

import avocado.core.display.iview;

/// Renderer for displaying things
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
