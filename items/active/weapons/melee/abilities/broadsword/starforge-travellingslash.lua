require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

StarforgeTravellingSlash = WeaponAbility:new()

function StarforgeTravellingSlash:init()
  self.cooldownTimer = self.cooldownTime
end

function StarforgeTravellingSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil and self.fireMode == "alt" and self.cooldownTimer == 0 and status.overConsumeResource("energy", self.energyUsage) then
    self:setState(self.windup)
  end
end

function StarforgeTravellingSlash:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  util.wait(self.stances.windup.duration)

  self:setState(self.fire)
end

function StarforgeTravellingSlash:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * mcontroller.facingDirection(), self.projectileOffset[2]})
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.power = self:damageAmount()

  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), self:aimVector(), false, params)

  animator.playSound(self.slashSound or "travelSlash")

  util.wait(self.stances.fire.duration)
  self.cooldownTimer = self.cooldownTime
end

function StarforgeTravellingSlash:aimVector()
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle)
  if self.fixedAimVector then
    aimVector = self.fixedAimVector
  end
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function StarforgeTravellingSlash:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier")
end

function StarforgeTravellingSlash:uninit()
end
