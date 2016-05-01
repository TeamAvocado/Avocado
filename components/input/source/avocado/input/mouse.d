module avocado.input.mouse;

/// Mouse state
struct State {
	/// State of all mouse buttons
	bool[8] buttons;
	/// x and y position of the mouse cursor
	int x, y;
	/// x and y offset of the mouse cursor since the last reset
	int offX, offY;

	/// Returns true if the button is pressed
	bool isButtonPressed(ubyte button) const {
		return buttons[button];
	}

	/// Resets the offset to 0,0
	void resetOffset() {
		offX = offY = 0;
	}
}

/// Current mouse state
static State* state() @property {
	return _state;
}

private static State* _state;

static this() {
	_state = new State();
}
