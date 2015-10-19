module avocado.entity.system;

import avocado.entity.world;

interface ISystem {
	void update(World world);
}
