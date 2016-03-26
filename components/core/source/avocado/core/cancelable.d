module avocado.core.cancelable;

/**
    The Cancelable event stucture implements an array of delegate with the arguments which are
    passed as template arguments.
*/

struct Cancelable(Args...) {
public:
	/// Adds a callback $(PARAM cb)
	void opOpAssign(string op : "~")(cbFunction cb) {
		add(cb);
	}

	/// Adds a callback $(PARAM cb)
	void opOpAssign(string op : "+")(cbFunction cb) {
		add(cb);
	}

	/// Adds a callback $(PARAM cb)
	void add(cbFunction cb) {
		callbacks ~= cb;
	}

	/// Removes a callback $(PARAM cb)
	void opOpAssign(string op : "-")(cbFunction cb) {
		remove(cb);
	}

	/// Removes a callback $(PARAM cb)
	void remove(cbFunction cb) {
		import std.algorithm : remove, SwapStrategy;

		callbacks = callbacks.remove!(a => a == cb, SwapStrategy.unstable);
	}

	/// Calls every functions with the arguments $(PARAM args)
	bool opCall(Args args) {
		foreach (fn; callbacks)
			if (!fn(args))
				return false;
		return true;
	}

private:
	alias cbFunction = bool delegate(Args);
	cbFunction[] callbacks;
}

unittest {
	Cancelable!bool events;

	int sum = 0;

	bool a(bool force) {
		sum++;
		return force;
	}

	bool b(bool force) {
		sum++;
		return force;
	}

	bool c(bool force) {
		sum++;
		return force;
	}

	events ~= &a;
	events += &b;
	events.add(&c);

	assert(events(true));
	assert(sum == 3);
	sum = 0;

	events -= &b;
	assert(!events(false));
	assert(sum == 1);
}
