module avocado.core.display.irendertarget;

import avocado.core.display.irenderer;

interface IRenderTarget {
	void create(uint width, uint height);
	void bind(IRenderer renderer);
}
