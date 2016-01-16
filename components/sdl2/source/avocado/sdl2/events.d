module avocado.sdl2.events;

import avocado.sdl2;

struct ControllerAxisEvent {
	uint type, timestamp;
	SDL_JoystickID which;
	ubyte axis;
	short value;
}

struct ControllerButtonEvent {
	uint type, timestamp;
	SDL_JoystickID which;
	ubyte button, state;
}

struct ControllerDeviceEvent {
	uint type, timestamp;
	SDL_JoystickID which;
}

struct DollarGestureEvent {
	uint type, timestamp;
	SDL_TouchID touchId;
	SDL_GestureID gestureId;
	uint numFingers;
	float errror, x, y;
}

struct DropEvent {
	uint type, timestamp;
	string file;
}

struct TouchFingerEvent {
	uint type, timestamp;
	SDL_TouchID touchId;
	SDL_FingerID fingerId;
	float x, y, dx, dy, pressure;
}

struct KeyboardEvent {
	uint type, timestamp;
	uint windowID;
	ubyte state, repeat;
	SDL_Keysym keysym;
}

struct JoyAxisEvent {
	uint type, timestamp;
	SDL_JoystickID which;
	ubyte axis;
	short value;
}

struct JoyBallEvent {
	uint type, timestamp;
	SDL_JoystickID which;
	ubyte ball;
	short xrel, yrel;
}

struct JoyHatEvent {
	uint type, timestamp;
	SDL_JoystickID which;
	ubyte hat, value;
}

struct JoyButtonEvent {
	uint type, timestamp;
	SDL_JoystickID which;
	ubyte button, state;
}

struct JoyDeviceEvent {
	uint type, timestamp;
	uint which;
}

struct MouseMotionEvent {
	uint type, timestamp, windowID, which, state;
	int x, y, xrel, yrel;
}

struct MouseButtonEvent {
	uint type, timestamp, windowID, which;
	ubyte button, state, clicks;
	int x, y;
}

struct MouseWheelEvent {
	uint type, timestamp, windowID, which;
	int x, y;
	uint direction;
}

struct MultiGestureEvent {
	uint type, timestamp;
	SDL_TouchID touchId;
	float dTheta, dDist, x, y;
	ushort numFingers;
}

struct TextEditingEvent {
	uint type, timestamp, windowID;
	string text;
	int start, length;
}

struct TextInputEvent {
	uint type, timestamp, windowID;
	string text;
}

struct CustomEvent {
	uint type, timestamp, windowID;
	int code;
	void* data1, data2;
}