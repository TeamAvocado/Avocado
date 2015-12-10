module avocado.sdl2;

public:

import derelict.sdl2.sdl;

/// Exception defaulting to SDL_GetError
class SDLException : Exception {
    public this(string msg = null, string file = __FILE__,
        size_t line = __LINE__, Throwable next = null) {
        import std.string : fromStringz;

        if (msg == null)
            msg = cast(string) fromStringz(SDL_GetError());
        super(msg, file, line, next);
    }
}

import avocado.sdl2.sdlwindow;

shared static this() {
    DerelictSDL2.load();
}
