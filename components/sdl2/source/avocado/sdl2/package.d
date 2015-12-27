module avocado.sdl2;

public:

import derelict.sdl2.sdl;

/// Exception defaulting to SDL_GetError
class SDLException : Exception {
	public this(string msg = null, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
		import std.string : fromStringz;

		if (msg == null)
			msg = cast(string)fromStringz(SDL_GetError());
		super(msg, file, line, next);
	}
}

enum MouseButton : ubyte {
	Left = SDL_BUTTON_LEFT,
	Middle = SDL_BUTTON_MIDDLE,
	Right = SDL_BUTTON_RIGHT,
	X1 = SDL_BUTTON_X1,
	X2 = SDL_BUTTON_X2,
}

import avocado.sdl2.key;
import avocado.sdl2.sdlwindow;

import avocado.input;

shared static this() {
	DerelictSDL2.load();
}
