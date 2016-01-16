module avocado.sdl2.sdlwindow;

import avocado.sdl2;

import avocado.core.display.irenderer;
import avocado.core.display.iview;
import avocado.core.cancelable;
import avocado.core.event;
import std.string : fromStringz, toStringz;
import std.conv : to;

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
		this(SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, title, flags);
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

	///
	ref auto onControllerAxis() @property {
		return _onControllerAxis;
	}
	///
	ref auto onControllerButton() @property {
		return _onControllerButton;
	}
	///
	ref auto onControllerDevice() @property {
		return _onControllerDevice;
	}
	///
	ref auto onDollarGesture() @property {
		return _onDollarGesture;
	}
	///
	ref auto onDrop() @property {
		return _onDrop;
	}
	///
	ref auto onTouchFinger() @property {
		return _onTouchFinger;
	}
	///
	ref auto onKeyboard() @property {
		return _onKeyboard;
	}
	///
	ref auto onJoyAxis() @property {
		return _onJoyAxis;
	}
	///
	ref auto onJoyBall() @property {
		return _onJoyBall;
	}
	///
	ref auto onJoyHat() @property {
		return _onJoyHat;
	}
	///
	ref auto onJoyButton() @property {
		return _onJoyButton;
	}
	///
	ref auto onJoyDevice() @property {
		return _onJoyDevice;
	}
	///
	ref auto onMouseMotion() @property {
		return _onMouseMotion;
	}
	///
	ref auto onMouseButton() @property {
		return _onMouseButton;
	}
	///
	ref auto onMouseWheel() @property {
		return _onMouseWheel;
	}
	///
	ref auto onMultiGesture() @property {
		return _onMultiGesture;
	}
	///
	ref auto onTextEditing() @property {
		return _onTextEditing;
	}
	///
	ref auto onTextInput() @property {
		return _onTextInput;
	}
	///
	ref auto onCustomEvent() @property {
		return _onCustomEvent;
	}
	///
	ref auto onShown() @property {
		return _onShown;
	}
	///
	ref auto onHidden() @property {
		return _onHidden;
	}
	///
	ref auto onExposed() @property {
		return _onExposed;
	}
	///
	ref auto onMoved() @property {
		return _onMoved;
	}

	/// Gets called when the window got resized
	/// Returns: an Event with width and height as parameters
	ref Event!(int, int) onResized() @property {
		return _onResized;
	}

	///
	ref auto onSizeChanged() @property {
		return _onSizeChanged;
	}
	///
	ref auto onMinimized() @property {
		return _onMinimized;
	}
	///
	ref auto onMaximized() @property {
		return _onMaximized;
	}
	///
	ref auto onRestored() @property {
		return _onRestored;
	}
	///
	ref auto onEnter() @property {
		return _onEnter;
	}
	///
	ref auto onLeave() @property {
		return _onLeave;
	}
	///
	ref auto onFocusGained() @property {
		return _onFocusGained;
	}
	///
	ref auto onFocusLost() @property {
		return _onFocusLost;
	}
	///
	ref auto onClose() @property {
		return _onClose;
	}

	///
	ref Trigger onClipboardUpdate() @property {
		return _onClipboardUpdate;
	}

	///
	ref Trigger onRenderTargetsReset() @property {
		return _onRenderTargetsReset;
	}

	///
	ref Trigger onAppTerminating() @property {
		return _onAppTerminating;
	}

	///
	ref Trigger onAppLowMemory() @property {
		return _onAppLowMemory;
	}

	///
	ref Trigger onAppWillEnterBackground() @property {
		return _onAppWillEnterBackground;
	}

	///
	ref Trigger onAppDidEnterBackground() @property {
		return _onAppDidEnterBackground;
	}

	///
	ref Trigger onAppWillEnterForeground() @property {
		return _onAppWillEnterForeground;
	}

	///
	ref Trigger onAppDidEnterForeground() @property {
		return _onAppDidEnterForeground;
	}

	/// Passes every event that is not handled by the update function
	ref auto onUnhandledEvent() @property {
		return _onUnhandledEvent;
	}

	/// Handles events and might display things.
	bool update() {
		SDL_Event event;
		while (SDL_PollEvent(&event)) {
			switch (event.type) {
			case SDL_APP_TERMINATING:
				_onAppTerminating();
				break;
			case SDL_APP_LOWMEMORY:
				_onAppLowMemory();
				break;
			case SDL_APP_WILLENTERBACKGROUND:
				_onAppWillEnterBackground();
				break;
			case SDL_APP_DIDENTERBACKGROUND:
				_onAppDidEnterBackground();
				break;
			case SDL_APP_WILLENTERFOREGROUND:
				_onAppWillEnterForeground();
				break;
			case SDL_APP_DIDENTERFOREGROUND:
				_onAppDidEnterForeground();
				break;
			case SDL_WINDOWEVENT:
				switch (event.window.event) {
				case SDL_WINDOWEVENT_SHOWN:
					_onShown();
					break;
				case SDL_WINDOWEVENT_HIDDEN:
					_onHidden();
					break;
				case SDL_WINDOWEVENT_EXPOSED:
					_onExposed();
					break;
				case SDL_WINDOWEVENT_MOVED:
					_onMoved(event.window.data1, event.window.data2);
					break;
				case SDL_WINDOWEVENT_RESIZED:
					_onResized(event.window.data1, event.window.data2);
					break;
				case SDL_WINDOWEVENT_SIZE_CHANGED:
					_onSizeChanged(event.window.data1, event.window.data2);
					break;
				case SDL_WINDOWEVENT_MINIMIZED:
					_onMinimized();
					break;
				case SDL_WINDOWEVENT_MAXIMIZED:
					_onMaximized();
					break;
				case SDL_WINDOWEVENT_RESTORED:
					_onRestored();
					break;
				case SDL_WINDOWEVENT_ENTER:
					_onEnter();
					break;
				case SDL_WINDOWEVENT_LEAVE:
					_onLeave();
					break;
				case SDL_WINDOWEVENT_FOCUS_GAINED:
					_onFocusGained();
					break;
				case SDL_WINDOWEVENT_FOCUS_LOST:
					_onFocusLost();
					break;
				case SDL_WINDOWEVENT_CLOSE:
					if (_onClose()) {
						close();
						return false;
					}
					break;
				default:
					debug throw new Exception("Not implemented window event: " ~ (cast(int)event.window.event).to!string);
					else
						break;
				}
				break;
			case SDL_KEYDOWN:
			case SDL_KEYUP:
				Keyboard.setKey(event.key.keysym.sym, event.type == SDL_KEYDOWN);
				_onKeyboard(KeyboardEvent(event.key.type, event.key.timestamp, event.key.windowID, event.key.state,
					event.key.repeat, event.key.keysym));
				break;
			case SDL_TEXTEDITING:
				_onTextEditing(TextEditingEvent(event.edit.type, event.edit.timestamp, event.edit.windowID,
					event.edit.text.ptr.fromStringz.idup, event.edit.start, event.edit.length));
				break;
			case SDL_TEXTINPUT:
				_onTextInput(TextInputEvent(event.text.type, event.text.timestamp, event.text.windowID,
					event.text.text.ptr.fromStringz.idup));
				break;
			case SDL_MOUSEMOTION:
				Mouse.state.x = event.motion.x;
				Mouse.state.y = event.motion.y;
				_onMouseMotion(MouseMotionEvent(event.motion.type, event.motion.timestamp, event.motion.windowID,
					event.motion.which, event.motion.state, event.motion.x, event.motion.y, event.motion.xrel, event.motion.yrel));
				break;
			case SDL_MOUSEBUTTONDOWN:
			case SDL_MOUSEBUTTONUP:
				Mouse.state.x = event.button.x;
				Mouse.state.y = event.button.y;
				Mouse.state.buttons[event.button.button] = event.button.state == SDL_PRESSED;
				_onMouseButton(MouseButtonEvent(event.button.type, event.button.timestamp, event.button.windowID,
					event.button.which, event.button.button, event.button.state, event.button.clicks, event.button.y));
				break;
			case SDL_MOUSEWHEEL:
				_onMouseWheel(MouseWheelEvent(event.wheel.type, event.wheel.timestamp, event.wheel.windowID,
					event.wheel.which, event.wheel.x, event.wheel.y, event.wheel.direction));
				break;
			case SDL_JOYAXISMOTION:
				_onJoyAxis(JoyAxisEvent(event.jaxis.type, event.jaxis.timestamp, event.jaxis.which, event.jaxis.axis, event.jaxis.value));
				break;
			case SDL_JOYBALLMOTION:
				_onJoyBall(JoyBallEvent(event.jball.type, event.jball.timestamp, event.jball.which, event.jball.ball,
					event.jball.xrel, event.jball.yrel));
				break;
			case SDL_JOYHATMOTION:
				_onJoyHat(JoyHatEvent(event.jhat.type, event.jhat.timestamp, event.jhat.which, event.jhat.hat, event.jhat.value));
				break;
			case SDL_JOYBUTTONDOWN:
			case SDL_JOYBUTTONUP:
				_onJoyButton(JoyButtonEvent(event.jbutton.type, event.jbutton.timestamp, event.jbutton.which,
					event.jbutton.button, event.jbutton.state));
				break;
			case SDL_JOYDEVICEADDED:
			case SDL_JOYDEVICEREMOVED:
				_onJoyDevice(JoyDeviceEvent(event.jdevice.type, event.jdevice.timestamp, event.jdevice.which));
				break;
			case SDL_CONTROLLERAXISMOTION:
				_onControllerAxis(ControllerAxisEvent(event.caxis.type, event.caxis.timestamp, event.caxis.which,
					event.caxis.axis, event.caxis.value));
				break;
			case SDL_CONTROLLERBUTTONDOWN:
			case SDL_CONTROLLERBUTTONUP:
				_onControllerButton(ControllerButtonEvent(event.cbutton.type, event.cbutton.timestamp,
					event.cbutton.which, event.cbutton.button, event.cbutton.state));
				break;
			case SDL_CONTROLLERDEVICEADDED:
			case SDL_CONTROLLERDEVICEREMOVED:
			case SDL_CONTROLLERDEVICEREMAPPED:
				_onControllerDevice(ControllerDeviceEvent(event.cdevice.type, event.cdevice.timestamp, event.cdevice.which));
				break;
			case SDL_FINGERDOWN:
			case SDL_FINGERUP:
			case SDL_FINGERMOTION:
				_onTouchFinger(TouchFingerEvent(event.tfinger.type, event.tfinger.timestamp, event.tfinger.touchId,
					event.tfinger.fingerId, event.tfinger.x, event.tfinger.y, event.tfinger.dx, event.tfinger.dy, event.tfinger.pressure));
				break;
			case SDL_DOLLARGESTURE:
			case SDL_DOLLARRECORD:
				_onDollarGesture(DollarGestureEvent(event.dgesture.type, event.dgesture.timestamp,
					event.dgesture.touchId, event.dgesture.gestureId, event.dgesture.numFingers, event.dgesture.error,
					event.dgesture.x, event.dgesture.y));
				break;
			case SDL_MULTIGESTURE:
				_onMultiGesture(MultiGestureEvent(event.mgesture.type, event.mgesture.timestamp,
					event.mgesture.touchId, event.mgesture.dTheta, event.mgesture.dDist, event.mgesture.x,
					event.mgesture.y, event.mgesture.numFingers));
				break;
			case SDL_CLIPBOARDUPDATE:
				_onClipboardUpdate();
				break;
			case SDL_DROPFILE:
				string file = event.drop.file.fromStringz().idup;
				SDL_free(event.drop.file);
				_onDrop(DropEvent(event.drop.type, event.drop.timestamp, file));
				break;
			case SDL_RENDER_TARGETS_RESET:
				_onRenderTargetsReset();
				break;
			case SDL_USEREVENT:
				_onCustomEvent(CustomEvent(event.user.type, event.user.timestamp, event.user.windowID, event.user.code,
					event.user.data1, event.user.data2));
				break;
			default:
				_onUnhandledEvent(event);
				break;
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
		int x;
		SDL_GetWindowSize(_window, &x, null);
		return x;
	}

	/// Dynamically sets the height of the window.
	@property void height(int height) {
		SDL_SetWindowSize(_window, width, height);
	}

	/// Dynamically gets the height of the window.
	@property int height() {
		int y;
		SDL_GetWindowSize(_window, null, &y);
		return y;
	}

	/// Dynamically sets the maximum width of the window.
	@property void maxWidth(int maxWidth) {
		SDL_SetWindowMaximumSize(_window, maxWidth, maxHeight);
	}

	/// Dynamically gets the maximum width of the window.
	@property int maxWidth() {
		int x;
		SDL_GetWindowMaximumSize(_window, &x, null);
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
		int x;
		SDL_GetWindowMinimumSize(_window, &x, null);
		return x;
	}

	/// Dynamically sets the minimum height of the window.
	@property void minHeight(int minHeight) {
		SDL_SetWindowMinimumSize(_window, minWidth, minHeight);
	}

	/// Dynamically gets the minimum height of the window.
	@property int minHeight() {
		int y;
		SDL_GetWindowMinimumSize(_window, null, &y);
		return y;
	}

	/// Dynamically sets the x position of the window.
	@property void x(int x) {
		SDL_SetWindowPosition(_window, x, SDL_WINDOWPOS_UNDEFINED);
	}

	/// Dynamically gets the x position of the window.
	@property int x() {
		int x;
		SDL_GetWindowPosition(_window, &x, null);
		return x;
	}

	/// Dynamically sets the y position of the window.
	@property void y(int y) {
		SDL_SetWindowPosition(_window, SDL_WINDOWPOS_UNDEFINED, y);
	}

	/// Dynamically gets the y position of the window.
	@property int y() {
		int y;
		SDL_GetWindowPosition(_window, null, &y);
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
	Event!ControllerAxisEvent _onControllerAxis;
	Event!ControllerButtonEvent _onControllerButton;
	Event!ControllerDeviceEvent _onControllerDevice;
	Event!DollarGestureEvent _onDollarGesture;
	Event!DropEvent _onDrop;
	Event!TouchFingerEvent _onTouchFinger;
	Event!KeyboardEvent _onKeyboard;
	Event!JoyAxisEvent _onJoyAxis;
	Event!JoyBallEvent _onJoyBall;
	Event!JoyHatEvent _onJoyHat;
	Event!JoyButtonEvent _onJoyButton;
	Event!JoyDeviceEvent _onJoyDevice;
	Event!MouseMotionEvent _onMouseMotion;
	Event!MouseButtonEvent _onMouseButton;
	Event!MouseWheelEvent _onMouseWheel;
	Event!MultiGestureEvent _onMultiGesture;
	Event!TextEditingEvent _onTextEditing;
	Event!TextInputEvent _onTextInput;
	Event!CustomEvent _onCustomEvent;
	Event!SDL_Event _onUnhandledEvent;
	Trigger _onShown;
	Trigger _onHidden;
	Trigger _onExposed;
	Event!(int, int) _onMoved;
	Event!(int, int) _onResized;
	Event!(int, int) _onSizeChanged;
	Trigger _onMinimized;
	Trigger _onMaximized;
	Trigger _onRestored;
	Trigger _onEnter;
	Trigger _onLeave;
	Trigger _onFocusGained;
	Trigger _onFocusLost;
	Cancelable!() _onClose;
	Trigger _onClipboardUpdate;
	Trigger _onRenderTargetsReset;
	Trigger _onAppTerminating;
	Trigger _onAppLowMemory;
	Trigger _onAppWillEnterBackground;
	Trigger _onAppDidEnterBackground;
	Trigger _onAppWillEnterForeground;
	Trigger _onAppDidEnterForeground;

	SDL_GLContext _glcontext = null;
	SDL_Window* _window;
	int _windowID;
}
