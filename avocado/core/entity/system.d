module avocado.core.entity.system;

import avocado.core.entity.world;

///
interface ISystem {
    void update(World world);
}
