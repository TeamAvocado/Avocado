module avocado.sdl2.sdlwindow;

import avocado.sdl2;

import avocado.core.display.irenderer;
import avocado.core.display.iview;
import std.string : fromStringz, toStringz;

/// Window creation flags.
enum WindowFlags : uint {
    /// Fullscreen window with custom resolution.
    Fullscreen = SDL_WINDOW_FULLSCREEN,
    /// Fullscreen window without automatic resolution.
    FullscreenAuto = SDL_WINDOW_FULLSCREEN_DESKTOP,
    /// Directly show the window without calling `show();`
    Shown = SDL_WINDOW_SHOWN,
    /// Window is hidden by default and needs to be shown by `show();`
    Hidden = SDL_WINDOW_HIDDEN,
    /// Window has no border or title bar.
    Borderless = SDL_WINDOW_BORDERLESS,
    /// Window is resizable.
    Resizable = SDL_WINDOW_RESIZABLE,
    /// Window is initially started in minimized mode.
    Minimized = SDL_WINDOW_MINIMIZED,
    /// Window is initially started in maximized mode.
    Maximized = SDL_WINDOW_MAXIMIZED,
    /// Window directly gains input and mouse focus on startup.
    Focused = SDL_WINDOW_INPUT_FOCUS | SDL_WINDOW_MOUSE_FOCUS,
    /// Window allows high DPI monitors.
    HighDPI = SDL_WINDOW_ALLOW_HIGHDPI,
    /// Combination of `Shown | Focused | OpenGL`
    Default = Shown | Focused | OpenGL,
    /// Use this window with OpenGL.
    OpenGL = SDL_WINDOW_OPENGL,
}

/// Class wrapping SDL_Window* as IView. Supported Renderers: GL3
class SDLWindow : IView {
public:
    /// Creates a new centered window with specified title and flags on a 800x480 resolution.
    this(string title = "Avocado", uint flags = WindowFlags.Default) {
        this(800, 480, title, flags);
    }

    /// Creates a new centered window with specified dimensions, title and flags.
    this(int width, int height, string title = "Avocado", uint flags = WindowFlags.Default) {
        this(SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, title,
            flags);
    }

    /// Creates a new window with specified parameters.
    this(int x, int y, int width, int height, string title, uint flags = WindowFlags.Default) {
        SDL_Init(SDL_INIT_EVERYTHING);

        _window = SDL_CreateWindow(title.toStringz(), x, y, width, height, flags);
        if (!valid)
            throw new SDLException();
        _windowID = SDL_GetWindowID(_window);
    }

    ~this() {
        if (valid)
            close();
    }

    /// Create a context for a renderer
    void createContext(IRenderer renderer) {
        if (renderer.type == "GL3") {
            if (!_glcontext) {
                SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
                SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 0);

                SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
                SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
                SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);

                _glcontext = SDL_GL_CreateContext(_window);
                if (!_glcontext)
                    throw new SDLException();

                SDL_GL_SetSwapInterval(0);
            }
        } else
            throw new Exception("Invalid renderer for SDLWindow: " ~ renderer.type);
    }

    /// Activates the context for rendering
    void activateContext(IRenderer renderer) {
        if (renderer.type == "GL3") {
            if (SDL_GL_MakeCurrent(_window, _glcontext) < 0)
                throw new SDLException();
        } else
            throw new Exception("Invalid renderer for SDLWindow: " ~ renderer.type);
    }

    /// Handles events and might display things.
    bool update() {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            switch (event.type) {
            case SDL_QUIT:
                close();
                return false;
            default: break; // TODO: Add custom event handling for SDL_QUIT, add other events for keyboard etc
            }
        }
        return true;
    }

    /// Get the window handle as SDL_Window*
    void* getHandle() {
        return _window;
    }

    /// Returns SDL2
    @property string type() const {
        return "SDL2";
    }

    /// Dynamically sets the title of the window.
    @property void title(string title) {
        SDL_SetWindowTitle(_window, title.toStringz());
    }

    /// Dynamically gets the title of the window.
    @property string title() {
        string title = SDL_GetWindowTitle(_window).fromStringz().dup;
        return title;
    }

    /// Dynamically sets the width of the window.
    @property void width(int width) {
        SDL_SetWindowSize(_window, width, height);
    }

    /// Dynamically gets the width of the window.
    @property int width() {
        int x, y;
        SDL_GetWindowSize(_window, &x, &y);
        return x;
    }

    /// Dynamically sets the height of the window.
    @property void height(int height) {
        SDL_SetWindowSize(_window, width, height);
    }

    /// Dynamically gets the height of the window.
    @property int height() {
        int x, y;
        SDL_GetWindowSize(_window, &x, &y);
        return y;
    }

    /// Dynamically sets the maximum width of the window.
    @property void maxWidth(int maxWidth) {
        SDL_SetWindowMaximumSize(_window, maxWidth, maxHeight);
    }

    /// Dynamically gets the maximum width of the window.
    @property int maxWidth() {
        int x, y;
        SDL_GetWindowMaximumSize(_window, &x, &y);
        return x;
    }

    /// Dynamically sets the maximum height of the window.
    @property void maxHeight(int maxHeight) {
        SDL_SetWindowMaximumSize(_window, maxWidth, maxHeight);
    }

    /// Dynamically gets the maximum height of the window.
    @property int maxHeight() {
        int x, y;
        SDL_GetWindowMaximumSize(_window, &x, &y);
        return y;
    }

    /// Dynamically sets the minimum width of the window.
    @property void minWidth(int minWidth) {
        SDL_SetWindowMinimumSize(_window, minWidth, minHeight);
    }

    /// Dynamically gets the minimum width of the window.
    @property int minWidth() {
        int x, y;
        SDL_GetWindowMinimumSize(_window, &x, &y);
        return x;
    }

    /// Dynamically sets the minimum height of the window.
    @property void minHeight(int minHeight) {
        SDL_SetWindowMinimumSize(_window, minWidth, minHeight);
    }

    /// Dynamically gets the minimum height of the window.
    @property int minHeight() {
        int x, y;
        SDL_GetWindowMinimumSize(_window, &x, &y);
        return y;
    }

    /// Dynamically sets the x position of the window.
    @property void x(int x) {
        SDL_SetWindowPosition(_window, x, y);
    }

    /// Dynamically gets the x position of the window.
    @property int x() {
        int x, y;
        SDL_GetWindowPosition(_window, &x, &y);
        return x;
    }

    /// Dynamically sets the y position of the window.
    @property void y(int y) {
        SDL_SetWindowPosition(_window, x, y);
    }

    /// Dynamically gets the y position of the window.
    @property int y() {
        int x, y;
        SDL_GetWindowPosition(_window, &x, &y);
        return y;
    }

    /// Shows the window if hidden.
    void show() {
        SDL_ShowWindow(_window);
    }

    /// Hides the window.
    void hide() {
        SDL_HideWindow(_window);
    }

    /// Minimizes the window.
    void minimize() {
        SDL_MinimizeWindow(_window);
    }

    /// Maximizes the window.
    void maximize() {
        SDL_MaximizeWindow(_window);
    }

    /// Restores the window state from minimized or maximized.
    void restore() {
        SDL_RestoreWindow(_window);
    }

    /// Raises the window to top and focuses it for input.
    void focus() {
        SDL_RaiseWindow(_window);
    }

    /// Closes the window and invalidates it.
    void close() {
        SDL_DestroyWindow(_window);
        _window = null;
    }

    /// Returns if the is still open.
    /// See_Also: Window.valid
    @property bool open() {
        return valid;
    }

    /// Returns if the window is still open.
    /// See_Also: Window.open
    @property bool valid() {
        return _window !is null;
    }

private:
    SDL_GLContext _glcontext = null;
    SDL_Window* _window;
    int _windowID;
}
