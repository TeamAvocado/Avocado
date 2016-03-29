module util.font;

import app;

import avocado.core;
import avocado.gl3;
import avocado.bmfont;

alias CharStream = BufferElement!("Char", 4, float, false, BufferType.Element, true);
alias PositionStream2D = BufferElement!("CharPosition", 2, float, false, BufferType.Element, true);

alias FontStream = GL3Mesh!(PositionElement2D, CharStream, PositionStream2D);

final class Text {
public:
	this(Font font, int max = 255) {
		_text = cast(FontStream)new FontStream().addPositionArray([vec2(0, 0), vec2(1, 0), vec2(0, 1), vec2(0, 1), vec2(1,
			0), vec2(1, 1)]).reserveChar(max).reserveCharPosition(max).generate();
		_max = max;
		_font = font;
		_iWidth = 1.0f / font.value.common.scaleW;
		_iHeight = 1.0f / font.value.common.scaleH;
		_chars.reserve(max);
		_positions.reserve(max);
		_text.fillChar(_chars);
		_text.fillCharPosition(_positions);
	}

	void text(dstring text) {
		_textStr = text;
		_chars.length = _positions.length = 0;
		int x = 0;
		int y = 0;
		dchar last;
		foreach (c; text) {
			auto info = _font.value.getChar(c);
			_chars ~= vec4(info.x * _iWidth, info.y * _iHeight, info.width * _iWidth, info.height * _iHeight);
			_positions ~= vec2((x + info.xoffset) * _iWidth, (y + info.yoffset - _font.value.common.lineHeight) * _iHeight);
			if (last != dchar.init)
				x += _font.value.getKerning(last, c);
			x += info.xadvance;
			last = c;
		}
	}

	dstring text() {
		return _textStr;
	}

	void draw(Renderer renderer, Shader shader) {
		_text.fillChar(_chars);
		_text.fillCharPosition(_positions);
		renderer.bind(shader);
		foreach (slot, tex; _font.pages)
			renderer.bind(tex, cast(int)slot);
		renderer.drawMeshInstanced(_text, cast(int)_chars.length);
	}

private:
	dstring _textStr;
	int _max;
	float _iWidth;
	float _iHeight;
	vec4[] _chars;
	vec2[] _positions;
	Font _font;
	FontStream _text;
}
