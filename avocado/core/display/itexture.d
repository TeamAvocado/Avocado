module avocado.core.display.itexture;

import avocado.core.display.irenderer;
import avocado.core.display.bitmap;

/// Texture optimized for rendering
interface ITexture {
    void create(int width, int height, in void[] pixels);
    void fromBitmap(in Bitmap bitmap, in string name = "Bitmap");
    Bitmap toBitmap();
    void resize(int width, int height, in void[] pixels = null);
    void bind(IRenderer renderer, int unit);
    @property int width();
    @property int height();
}
