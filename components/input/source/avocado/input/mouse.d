module avocado.input.mouse;

struct State {
	/// State of all mouse buttons
	bool[8] buttons;
	/// x and y position of the mouse cursor
	int x, y;

	bool isButtonDown(ubyte key) {
		return buttons[key];
	}

	bool isButtonUp(ubyte key) {
		return !buttons[key];
	}
}

static State* state() @property {
	return _state;
}

private static State* _state;

static this() {
	_state = new State();
}
