module avocado.core.utilities.fpslimiter;

import std.datetime : Clock, msecs;
import core.thread : Thread;

/// Limits the fps via a wait function
final class FPSLimiter {
public:
	/// Construct the FPSLimiter object with the $(PARAM targetFPS).
	this(int targetFPS) {
		this._targetFPS = targetFPS;

		_lastTime = Clock.currAppTick().msecs;
	}

	/**
		Sleeps so the engine will run at the targetfps.
		Run this in the end of every main loop tick.
	*/
	void wait() {
		if (_targetFPS == 0)
			return;
		immutable int increment = 1000 / _targetFPS;
		_lastTime += increment;
		long sleep = _lastTime - Clock.currAppTick().msecs;
		if (sleep > 0)
			Thread.sleep(sleep.msecs);
	}

	/// Get/Set the target fps.
	@property ref int targetFPS() {
		return _targetFPS;
	}

private:
	int _targetFPS;
	long _lastTime;
}
