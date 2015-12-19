module avocado.core.utilities.matrixstack;

import gl3n.linalg;
static import gl3n.ext.matrixstack;

/// Mixin including property for wrapping gl3n.matrixstack
mixin template MatrixStack(string name, T = mat4) {
    mixin("@property ref auto " ~ name ~ "() { return stack; }");
    private gl3n.ext.matrixstack.MatrixStack!T stack;
}
