module avocado.core.task;

import core.sync.mutex;
import core.thread;

import std.algorithm;
import std.datetime.stopwatch;
import std.range;
import std.variant;

__gshared long eventCounter;

long nextEvent() @trusted {
	return ++eventCounter;
}

class TaskPool {
	struct EventTask {
		Task task;
		bool notified;
	}

	Task currentTask;

	long[] notifiedEvents;
	EventTask[] eventTasks;
	Task[] tasks;

	void delegate(ref Task, Throwable) handleException;

	this() {
		if (!__ctfe) {
			eventTasks.reserve(1024);
			tasks.reserve(256);
			notifiedEvents.reserve(128);
		}
		handleException = (ref t, ex) { throw ex; };
	}

	bool hasWork() const @property {
		return tasks.length || eventTasks.length;
	}

	void notify(long event) {
		notifiedEvents ~= event;
	}

	void put(Task task) {
		if (task.event == 0)
			tasks ~= task;
		else {
			auto eventTask = EventTask(task, false);
			auto tri = assumeSorted!"a.task.event < b.task.event"(eventTasks).trisect(eventTask);
			auto i = tri[0].length + tri[1].length;
			eventTasks.length++;
			eventTasks[i + 1 .. $] = eventTasks[i .. $ - 1];
			eventTasks[i] = eventTask;
		}
	}

	void tick() {
		auto eventTasks = assumeSorted!"a.task.event < b.task.event"(this.eventTasks);
		foreach (event; notifiedEvents) {
			foreach (ref task; eventTasks.equalRange(EventTask(Task.inMemory(event, null), false))) {
				if (!task.notified)
					task.notified = true;
			}
		}
		notifiedEvents.length = 0;
		version (TasksUnstableOrder) {
			foreach_reverse (i, ref task; eventTasks) {
				if (task.notified) {
					if (task.task.fiber.state == Fiber.State.TERM) {
						eventTasks[i] = eventTasks[$ - 1];
						eventTasks.length--;
					} else {
						currentTask = task.task;
						auto ex = task.task.fiber.call(Rethrow.no);
						currentTask = Task.init;
						if (ex)
							handleException(task.task, ex);
					}
				}
			}
			foreach_reverse (i, ref task; tasks) {
				if (task.fiber.state == Fiber.State.TERM) {
					tasks[i] = tasks[$ - 1];
					tasks.length--;
				} else {
					currentTask = task;
					auto ex = task.fiber.call(Rethrow.no);
					currentTask = Task.init;
					if (ex)
						handleException(task, ex);
				}
			}
		} else {
			for (ptrdiff_t i; i < eventTasks.length; i++) {
				if (eventTasks[i].notified) {
					if (eventTasks[i].task.fiber.state == Fiber.State.TERM) {
						eventTasks = eventTasks.remove(i);
						i--;
					} else {
						currentTask = eventTasks[i].task;
						auto ex = eventTasks[i].task.fiber.call!(Fiber.Rethrow.no);
						currentTask = Task.init;
						if (ex)
							handleException(eventTasks[i].task, ex);
					}
				}
			}
			for (ptrdiff_t i; i < tasks.length; i++) {
				if (tasks[i].fiber.state == Fiber.State.TERM) {
					tasks = tasks.remove(i);
					i--;
				} else {
					currentTask = tasks[i];
					auto ex = tasks[i].fiber.call!(Fiber.Rethrow.no);
					currentTask = Task.init;
					if (ex)
						handleException(tasks[i], ex);
				}
			}
		}
	}
}

__gshared TaskPool gTaskPool;

__gshared Variant[const(Fiber)] gFiberStore;
__gshared Mutex gFiberStoreMutex;

void setFiberStore(const Fiber fiber, Variant v) {
	synchronized (gFiberStoreMutex)
		gFiberStore[fiber] = v;
}

struct Task {
	private this(long event, Fiber fiber) {
		this.event = event;
		this.fiber = fiber;
	}

	/// The event to trigger this task on, or 0 for always.
	long event;
	Fiber fiber;

	/// Creates a task but does not register it.
	static Task inMemory(long event, Fiber fiber) {
		return Task(event, fiber);
	}

	/// Creates a task and registers it.
	static Task register(long event, Fiber fiber) {
		auto ret = Task(event, fiber);
		gTaskPool.put(ret);
		return ret;
	}

	static Task create(T)(T callback) {
		Fiber fib;
		static if (is(T : Fiber))
			fib = callback;
		else static if (is(typeof(callback()) == void))
			fib = new Fiber(callback);
		else {
			fib = new Fiber({ auto ret = callback(); setFiberStore(cast(const)fib, Variant(ret)); });
			fib = fib;
		}
		fib.call();
		return register(0, fib);
	}

	static Task wait(Duration d) {
		return Timer.wait(d);
	}

	void join() {
		assert(fiber);
		if (fiber == gTaskPool.currentTask.fiber)
			throw new Exception("Attempted to join self");
		while (fiber.state != Fiber.State.TERM)
			Fiber.yield();
	}

	bool opEquals(Task b) {
		return event == b.event && fiber == b.fiber;
	}
}

Task await(Task[] tasks...) {
	assert(tasks.length > 0);
	foreach (ref task; tasks) {
		assert(task.fiber);
		if (task.fiber == gTaskPool.currentTask.fiber)
			throw new Exception("Attempted to join self");
	}
	while (true) {
		foreach (task; tasks) {
			while (task.fiber.state == Fiber.State.TERM)
				return task;
		}
		Fiber.yield();
	}
}

bool hasResult(ref in Task t) @property @trusted {
	Variant* store;
	synchronized (gFiberStoreMutex) {
		store = t.fiber in gFiberStore;
	}
	return !!store;
}

T result(T)(ref inout Task t) @property @trusted {
	Variant* store;
	synchronized (gFiberStoreMutex) {
		store = t.fiber in gFiberStore;
	}
	if (!store)
		return T.init;
	else static if (is(T == Variant*))
		return store;
	else static if (is(T == Variant))
		return *store;
	else
		return store.get!T;
}

struct Timer {
	private static TimerImpl instance;

	static Task wait(Duration d) {
		auto ret = Task.register(nextEvent, new Fiber(function() {  }, 4096, 0));
		instance.register(ret.event, d);
		return ret;
	}
}

class TimerImpl : Fiber {
	struct Waiter {
		StopWatch sw;
		Duration time;
		long event;
	}

	Waiter[] waiters;

	this() {
		super(&run);
	}

	void register(long event, Duration time) {
		waiters ~= Waiter(StopWatch(AutoStart.yes), time, event);
	}

	private void run() {
		waiters.reserve(512);
		while (true) {
			foreach_reverse (i, ref waiter; waiters) {
				if (waiter.sw.peek >= waiter.time) {
					gTaskPool.notify(waiter.event);
					waiters[i] = waiters[$ - 1];
					waiters.length--;
				}
			}
			Fiber.yield();
		}
	}
}

shared static this() {
	gFiberStoreMutex = new Mutex();
	gTaskPool = new TaskPool();
	Timer.instance = new TimerImpl();
	Task.register(0, Timer.instance);
}

unittest {
	import std.stdio;

	auto t = Task.create({
		writeln("a");
		auto computation1 = Task.create({ Task.wait(3.seconds).join(); return 1; });
		auto computation2 = Task.create({ Task.wait(2.seconds).join(); return 2; });
		Task.wait(1.seconds).join();
		writeln("b");
		auto first = await(computation1, computation2);
		writeln("c: ", computation2.result!int);
	});

	while (gTaskPool.hasWork)
		gTaskPool.tick();
}
