require "/scripts/vec2.lua"
require "/scripts/util.lua"

starforge_bounceProjectile_init = init
function init(...) if starforge_bounceProjectile_init then starforge_bounceProjectile_init(...) end
  self.bounceConfig = config.getParameter("bounceConfig")
  self.lastVelocity = mcontroller.velocity()
end

starforge_bounceProjectile_update = update
function update(dt) if starforge_bounceProjectile_update then starforge_bounceProjectile_update(dt) end
  self.lastVelocity = mcontroller.velocity()
end

starforge_bounceProjectile_destroy = destroy
function destroy(...) if starforge_bounceProjectile_destroy then starforge_bounceProjectile_destroy(...) end
  if self.bounceConfig then
    local params = self.bounceConfig.projectileParameters
    params.power = projectile.power() * (self.bounceConfig.inheritDamageFactor or 1)
    params.speed = -vec2.mag(self.lastVelocity) * (self.bounceConfig.inheritSpeedFactor or 1)
    local movementX = self.lastVelocity[1] > 0 and 1 or -1
    world.spawnProjectile(
      self.bounceConfig.projectileType or "standardbullet", 
      mcontroller.position(), 
      projectile.sourceEntity() or entity.id(), 
      vec2.norm(vec2.rotate(self.lastVelocity, movementX * util.toRadians((self.bounceConfig.angleAdjust or 0) + (math.random() * (self.bounceConfig.angleVariation or 0))))),
      false,
      params
    )
  end
end
