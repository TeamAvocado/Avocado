module avocado.gl3.gl3renderer;

import avocado.gl3;

import derelict.sdl2.sdl;

import avocado.core.display.iview;
import avocado.core.display.irenderer;

/// Renderer using OpenGL3.2. Supported view types: SDL2
class GL3Renderer : IRenderer {
    /// Registers the view with this renderer
    void register(IView view) {
        if (view.type == "SDL2") {
            DerelictGL3.load();
            view.createContext(this);
            DerelictGL3.reload();
            view.activateContext(this);
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
            SDL_GL_SwapWindow(cast(SDL_Window*) view.getHandle);
        } else
            assert(0, "Unsupported window type for GL3Renderer: " ~ view.type);
    }

    /// Identifier for this renderer
    @property string type() const {
        return "GL3";
    }
}
