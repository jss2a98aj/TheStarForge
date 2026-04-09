require "/scripts/vec2.lua"
require "/scripts/util.lua"

starforge_spinningProjectile_init = init
function init(...) if starforge_spinningProjectile_init then starforge_spinningProjectile_init(...) end
  self.spinDirection = config.getParameter("spinDirection", -1)
  self.spinRate = config.getParameter("spinRate", 0.5)
  self.minSpinSpeed = config.getParameter("minSpinSpeed", 25)
  self.ignoreVelocity = config.getParameter("ignoreVelocity", false)
  self.countMovementDirection = config.getParameter("countMovementDirection", false)
end

starforge_spinningProjectile_update = update
function update(dt) if starforge_spinningProjectile_update then starforge_spinningProjectile_update(dt) end
  --Spinning
  local direction = (self.countMovementDirection and util.toDirection(mcontroller.velocity()[1]) or 1) * self.spinDirection
  local speed = math.max(self.minSpinSpeed, self.ignoreVelocity and 1 or vec2.mag(mcontroller.velocity()))
  mcontroller.setRotation(mcontroller.rotation() + (speed * self.spinRate) * (dt * direction))
end