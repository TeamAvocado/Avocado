module avocado.core.event;

/**
	The Event stucture implement a array of delegate with the arguments which are
	passed as template arguments.
*/

struct Event(Args...) {
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
    void opCall(Args args) {
        foreach (fn; callbacks)
            fn(args);
    }

private:
    alias cbFunction = void delegate(Args);
    cbFunction[] callbacks;
}

unittest {
    Event!int events;

    int sum = 0;

    void a(int x) {
        sum += x;
    }

    void b(int x) {
        sum += x;
    }

    void c(int x) {
        sum += x;
    }

    events ~= &a;
    events += &b;
    events.add(&c);

    events(1);
    assert(sum == 3);
    sum = 0;

    events -= &b;
    events(2);
    assert(sum == 4);
}
