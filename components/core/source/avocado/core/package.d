module avocado.core;

public:
import avocado.core.display.bitmap;
import avocado.core.display.imesh;
import avocado.core.display.irenderer;
import avocado.core.display.ishader;
import avocado.core.display.itexture;
import avocado.core.display.iview;
import avocado.core.entity.component;
import avocado.core.entity.entity;
import avocado.core.entity.system;
import avocado.core.entity.world;
import avocado.core.gui.control;
import avocado.core.resource.defaultproviders;
import avocado.core.resource.resourceprovider;
import avocado.core.utilities.fpslimiter;
import avocado.core.util;
import avocado.core.cancelable;
import avocado.core.engine;
import avocado.core.event;