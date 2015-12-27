module avocado.input.keyboard;

struct State {
	/// State of every key
	bool[uint] keys;

	/// Returns true if the key is pressed
	bool isKeyPressed(uint key) {
		return !!(key in keys);
	}
}

static State* state() @property {
	return _state;
}

static void setKey(uint key, bool pressed) {
	if (pressed)
		_state.keys[key] = true;
	else
		_state.keys.remove(key);
}

private static State* _state;

static this() {
	_state = new State();
}
