module avocado.core.display.ishader;

import avocado.core.display.irenderer;

interface IShader {
    void create(IRenderer renderer);
    void bind(IRenderer renderer);
    void set(T)(string name, T value);
}
