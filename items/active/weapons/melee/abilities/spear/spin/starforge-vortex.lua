require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

StarforgeVortex = WeaponAbility:new()

function StarforgeVortex:init()
  self:reset()
end

function StarforgeVortex:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and self.fireMode == "alt" then
    
    self:setState(self.StarforgeVortex)
  end
end

function StarforgeVortex:StarforgeVortex()
  self.weapon:setStance(self.stances.spin)
  self.weapon:updateAim()

  self.weapon.aimAngle = 0
  activeItem.setOutsideOfHand(true)

  local forceRegion = sb.jsonMerge(self.forceRegion, {})
  local currentSpinRate = 0
  local spinUpTimer = 0
  local spunUp = false
  while self.fireMode == "alt" and status.overConsumeResource("energy", self.energyUsage * self.dt) do
    spinUpTimer = math.min(self.spinUpTime, spinUpTimer + self.dt)
    local spinUpFactor = spinUpTimer/self.spinUpTime

    if spinUpFactor == 1 and not spunUp then
      spunUp = true
      status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})  
      animator.setAnimationState("spinSwoosh", "spin")
      animator.setParticleEmitterActive("spin", true)
    end

    currentSpinRate = self.spinRate * spinUpFactor
    self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(currentSpinRate * self.dt)

    forceRegion.controlForce = self.forceRegion.controlForce * spinUpFactor
    activeItem.setItemForceRegions({forceRegion})

    if spunUp then
      local damageArea = partDamageArea("spinSwoosh")
      self.weapon:setDamage(self.damageConfig, damageArea)
      mcontroller.controlModifiers({runningSuppressed=true})

      if self.maxFallSpeed and mcontroller.yVelocity() < self.maxFallSpeed and mcontroller.falling() and math.abs(world.gravity(mcontroller.position())) ~= 0 then
        mcontroller.controlApproachYVelocity(self.maxFallSpeed, 250)
      end
    end

    coroutine.yield()
  end

  self:reset()
end

function StarforgeVortex:reset()
  animator.setAnimationState("spinSwoosh", "idle")
  animator.setParticleEmitterActive("spin", false)
  activeItem.setItemForceRegions()
  activeItem.setOutsideOfHand(false)
  
  status.clearPersistentEffects("weaponMovementAbility")

  for part, state in pairs(self.resetAnimationStates or {}) do
    animator.setAnimationState(part, state)
  end

  self.cooldownTimer = self.cooldownTime
end

function StarforgeVortex:uninit()
  self:reset()
end
