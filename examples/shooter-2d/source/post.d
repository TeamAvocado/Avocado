module post;

import app;

import avocado.core;
import avocado.gl3;

class PostStart : ISystem {
private:
	Renderer renderer;
	View view;
	GL3Framebuffer fb;

public:
	this(View view, Renderer renderer, GL3Framebuffer fb) {
		this.renderer = renderer;
		this.view = view;
		this.fb = fb;
		renderer.unbindRendertarget(view.width, view.height);
	}

	final void update(World world) {
		renderer.begin(view);
		renderer.bind(fb);
		renderer.clear();
	}
}

enum BlurAmount = 4;

class PostEnd : ISystem {
private:
	Renderer renderer;
	View view;
	GL3Framebuffer origFb, fb1, fb2;
	Shader hblurShader, vblurShader, neonShader;
	IMesh postRect;
	float[BlurAmount * 2 + 1] kernel;

public:
	this(View view, Renderer renderer, GL3Framebuffer origFb, GL3Framebuffer fb1, GL3Framebuffer fb2, Shader hblurShader, Shader vblurShader, Shader neonShader) {
		this.renderer = renderer;
		this.view = view;
		this.origFb = origFb;
		this.fb1 = fb1;
		this.fb2 = fb2;
		this.hblurShader = hblurShader;
		this.vblurShader = vblurShader;
		this.neonShader = neonShader;
		postRect = new Shape().addPositionArray([vec2(0, 0), vec2(1, 0), vec2(1, 1), vec2(0, 0), vec2(1, 1), vec2(0, 1)]).generate();
		kernel = [0.000229f, 0.005977f, 0.060598f, 0.241732f, 0.382928f, 0.241732f, 0.060598f, 0.005977f, 0.000229f];
	}

	final void update(World world) {
		renderer.bind(fb1);
		renderer.clear();
		renderer.bind(hblurShader, null);
		hblurShader.set("kernel", kernel);
		hblurShader.set("width", view.width / 2);
		renderer.bind(origFb.color[0]);
		renderer.drawMesh(postRect);
		renderer.bind(fb2);
		renderer.clear();
		renderer.bind(vblurShader, null);
		vblurShader.set("kernel", kernel);
		vblurShader.set("width", view.width / 2);
		renderer.bind(fb1.color[0]);
		renderer.drawMesh(postRect);
		renderer.unbindRendertarget(view.width, view.height);
		renderer.clear();
		renderer.bind(neonShader, null);
		renderer.bind(fb2.color[0], 0);
		renderer.bind(origFb.color[0], 1);
		renderer.drawMesh(postRect);
		renderer.end(view);
	}
}
