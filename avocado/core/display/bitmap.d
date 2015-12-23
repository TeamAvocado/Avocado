module avocado.core.display.bitmap;

import imageformats;

/// Memory representation of an image.
struct Bitmap {
    /// width & height of this bitmap.
    int width, height;
    /// pixeldata in RGBA format.
    const(ubyte)[] pixels;

    /// Reads an image file with automatic color format
    static Bitmap fromFile(string file) {
        return Bitmap.fromIFImage(read_image(file, ColFmt.RGBA));
    }

    /// Reads an image from memory with automatic color format
    static Bitmap fromMemory(ubyte[] file) {
        return Bitmap.fromIFImage(read_image_from_mem(file, ColFmt.RGBA));
    }

    /// Creates a bitmap from an imageformats image
    static Bitmap fromIFImage(in IFImage image) {
        assert(image.c == ColFmt.RGBA);
        Bitmap b;
        b.width = cast(int) image.w;
        b.height = cast(int) image.h;
        b.pixels = image.pixels;
        return b;
    }
}
