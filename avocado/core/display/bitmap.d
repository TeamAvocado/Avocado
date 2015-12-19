module avocado.core.display.bitmap;

/// Memory representation of an image.
struct Bitmap {
    /// width & height of this bitmap.
    int width, height;
    /// pixeldata in BGRA format.
    ubyte[] pixels;
}
