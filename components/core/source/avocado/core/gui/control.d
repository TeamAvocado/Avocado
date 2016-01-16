module avocado.core.gui.control;

import avocado.core.display.iview;
import avocado.core.display.irenderer;
import avocado.core.util;

struct Rectangle {
	float x, y, width, height;

	vec2 position() @property {
		return vec2(x, y);
	}

	vec2 size() @property {
		return vec2(width, height);
	}

	vec4 f() @property {
		return vec4(x, y, width, height);
	}
}

enum Alignment : ubyte {
	Top = 1 << 0,
	Bottom = 1 << 1,
	Left = 1 << 2,
	Right = 1 << 3,

	TopLeft = Top | Left,
	TopCenter = Top | Left | Right,
	TopRight = Top | Right,
	MiddleLeft = Bottom | Top | Left,
	MiddleCenter = Bottom | Top | Left | Right,
	MiddleRight = Bottom | Top | Right,
	BottomLeft = Bottom | Left,
	BottomCenter = Bottom | Left | Right,
	BottomRight = Bottom | Right,
}

public byte getHorizontal(Alignment alignment) @nogc pure {
	if ((alignment & Alignment.Left) && !(alignment & Alignment.Right))
		return -1;
	else if (!(alignment & Alignment.Left) && (alignment & Alignment.Right))
		return 1;
	else if ((alignment & Alignment.Left) && (alignment & Alignment.Right))
		return 0;
	else
		return -1;
}

unittest {
	assert(Alignment.TopLeft.getHorizontal() == -1);
	assert(Alignment.MiddleCenter.getHorizontal() == 0);
	assert(Alignment.BottomRight.getHorizontal() == 1);
	assert(Alignment.Top.getHorizontal() == -1);
}

public byte getVertical(Alignment alignment) @nogc pure {
	if ((alignment & Alignment.Top) && !(alignment & Alignment.Bottom))
		return -1;
	else if (!(alignment & Alignment.Top) && (alignment & Alignment.Bottom))
		return 1;
	else if ((alignment & Alignment.Top) && (alignment & Alignment.Bottom))
		return 0;
	else
		return -1;
}

unittest {
	assert(Alignment.TopLeft.getVertical() == -1);
	assert(Alignment.MiddleCenter.getVertical() == 0);
	assert(Alignment.BottomRight.getVertical() == 1);
	assert(Alignment.Left.getVertical() == -1);
}

private float computePosition(in byte alignment, in float childPos, in float childSize, in float parentSize) @nogc pure {
	if (alignment == 1)
		return parentSize - childSize - childPos;
	else if (alignment == 0)
		return (parentSize - childSize) * 0.5f + childPos;
	else
		return childPos;
}

private Rectangle computePosition(in Alignment alignment, Rectangle child, in float parentWidth, in float parentHeight) @nogc pure {
	child.x = computePosition(alignment.getHorizontal, child.x, child.width, parentWidth);
	child.y = computePosition(alignment.getVertical, child.y, child.height, parentHeight);
	return child;
}

class Control {
public:
	this(IView containerWindow) {
		_containerWindow = containerWindow;
	}

	void draw(I2DRenderer renderer) {
		if (_visible) {
			renderer.fillRectangle(clientRectangle.f, _background);
			foreach (ref child; _children)
				child.draw(renderer);
		}
	}

	ref auto parent() @property {
		return _parent;
	}

	ref auto x() @property {
		return _x;
	}

	ref auto y() @property {
		return _y;
	}

	ref auto width() @property {
		return _width;
	}

	ref auto height() @property {
		return _height;
	}

	ref auto alignment() @property {
		return _align;
	}

	ref auto containerWindow() @property {
		return _containerWindow;
	}

	ref auto background() @property {
		return _background;
	}

	ref auto foreground() @property {
		return _foreground;
	}

	ref auto tabIndex() @property {
		return _tabIndex;
	}

	ref auto visible() @property {
		return _visible;
	}

	ref auto tabStop() @property {
		return _tabStop;
	}

	ref auto enabled() @property {
		return _enabled;
	}

	ref auto canFocus() @property {
		return _canFocus;
	}

	auto hasFocus() @property {
		return _hasFocus;
	}

	ref auto containsFocus() @property {
		if (hasFocus)
			return true;
		foreach (ref child; _children)
			if (child.containsFocus)
				return true;
		return false;
	}

	ref auto text() @property {
		return _text;
	}

	ref auto margin() @property {
		return _margin;
	}

	ref auto padding() @property {
		return _padding;
	}

	auto clientRectangle() @property {
		return computePosition(_align, Rectangle(_x + parentX + margin, _y + parentY + margin, _width + padding * 2,
			_height + padding * 2), parentWidth, parentHeight);
	}

	void addChild(Control child) {
		assert(child, "Invalid child");
		child._parent = this;
		_children ~= child;
	}

protected:

	float parentX() @property {
		if (_parent)
			return _parent.clientRectangle.x;
		else
			return 0;
	}

	float parentY() @property {
		if (_parent)
			return _parent.clientRectangle.y;
		else
			return 0;
	}

	float parentWidth() @property {
		if (_parent)
			return _parent.clientRectangle.width;
		else
			return _containerWindow.width;
	}

	float parentHeight() @property {
		if (_parent)
			return _parent.clientRectangle.height;
		else
			return _containerWindow.height;
	}

private:
	IView _containerWindow;
	Control _parent = null;
	Control[] _children;
	Alignment _align = Alignment.TopLeft;
	float _x = 0, _y = 0, _width = 0, _height = 0;
	vec4 _foreground = vec4(0, 0, 0, 1), _background = vec4(0.9f, 0.9f, 0.9f, 1);
	int _tabIndex = 0;
	bool _tabStop = true;
	bool _visible = true;
	bool _enabled = true;
	bool _canFocus = true;
	bool _hasFocus = true;
	string _text = "";
	float _margin = 0, _padding = 3;
}
