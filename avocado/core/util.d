module avocado.core.util;

public:

import gl3n.aabb;
import gl3n.frustum;
import gl3n.interpolate;
import gl3n.linalg;
import gl3n.math;
import gl3n.plane;
import gl3n.util;
import gl3n.ext.hsv;

import avocado.core.utilities.projection;

mixin template BasicComponent(string name, T) {
    import std.string;
    
    mixin(`final struct ` ~ name ~ ` {
        T value;
        alias value this;
        mixin(ComponentBase!(` ~ name ~ `));

        string toString() const {
            return value.to!string;
        }
    }`);
}