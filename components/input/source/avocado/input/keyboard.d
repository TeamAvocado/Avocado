module avocado.input.keyboard;

struct State {
	/// State of every key
	bool[uint] keys;

	///
	bool isKeyDown(uint key) {
		return (key in keys) !is null;
	}

	///
	bool isKeyUp(uint key) {
		return (key in keys)  is null;
	}
}

static State* state() @property {
	return _state;
}

static void setKey(uint key, bool click) {
	if (click)
		_state.keys[key] = true;
	else
		_state.keys.remove(key);
}

private static State* _state;

static this() {
	_state = new State();
}
