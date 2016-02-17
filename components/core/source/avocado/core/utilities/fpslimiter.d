module avocado.core.utilities.fpslimiter;

import std.datetime : Clock, hnsecs;
import core.thread : Thread;

/// Limits the fps via a wait function
final class FPSLimiter {
public:
	/// Construct the FPSLimiter object with the $(PARAM targetFPS).
	this(int targetFPS) {
		this._targetFPS = targetFPS;

		_lastTime = Clock.currStdTime;
	}

	/**
		Sleeps so the engine will run at the targetfps.
		Run this in the end of every main loop tick.
	*/
	void wait() {
		if (_targetFPS == 0)
			return;
		immutable increment = 10_000_000 / _targetFPS;
		_lastTime += increment;
		const sleep = _lastTime - Clock.currStdTime;
		if (sleep > 0)
			Thread.sleep(sleep.hnsecs);
	}

	/// Get/Set the target fps.
	@property ref int targetFPS() {
		return _targetFPS;
	}

private:
	int _targetFPS;
	long _lastTime;
}
