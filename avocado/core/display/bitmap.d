module avocado.core.display.bitmap;

import imageformats;

import avocado.core.resource.resourceprovider;

/// Memory representation of an image.
struct Bitmap {
    /// width & height of this bitmap.
    int width, height;
    /// pixeldata in RGBA format.
    const(ubyte)[] pixels;

    /// Reads an image file with automatic color format
    static Bitmap fromFile(in string file) {
        return Bitmap.fromIFImage(read_image(file, ColFmt.RGBA));
    }

    /// Reads an image from memory with automatic color format
    static Bitmap fromMemory(in ubyte[] file) {
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

/// Generic string loading and validation from a file
class BitmapProvider : IResourceProvider {
    /// Contains file value
    Bitmap value;
    string errorMsg;

    /// Creates a black and pink error texture
    void error() {
        enum ERR_SIZE = 1 << 2;
        value.width = ERR_SIZE;
        value.height = ERR_SIZE;
        ubyte[] pixels = new ubyte[ERR_SIZE * ERR_SIZE];
        for (int i = 0; i < ERR_SIZE * ERR_SIZE; i++) {
            int x = i % ERR_SIZE;
            int y = i / ERR_SIZE;
            bool pink = ((x & 1) && !(y & 1)) || (!(x & 1) && (y & 1));
            pixels[i * 4 + 0] = pink ? 255 : 0;
            pixels[i * 4 + 1] = 0;
            pixels[i * 4 + 2] = pink ? 255 : 0;
            pixels[i * 4 + 3] = 255;
        }
        value.pixels = pixels;
    }
    
    /// Returns the error message if an exception occurs
    @property string errorInfo() {
        return errorMsg;
    }

    /// Loads a resource from a memory stream
    bool load(ref ubyte[] stream) {
        try {
            value = Bitmap.fromMemory(stream);
            return true;
        } catch(Exception e) {
            errorMsg = e.msg;
            return false;
        }
    }

    /// True for .png, .bmp, .jpg and .tga
    bool canRead(string extension) {
        switch(extension) {
        case "png":
        case "jpg":
        case "jpeg":
        case "bmp":
        case "tga":
            return true;
        default:
            return false;
        }
    }

    /// Can cast to a Bitmap
    T opCast(T)() if (is(T == Bitmap)) {
        return value;
    }
}