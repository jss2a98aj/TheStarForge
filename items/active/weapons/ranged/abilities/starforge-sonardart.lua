require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"
require "/items/active/weapons/ranged/starforge-gunfire.lua"

StarforgeSonarDart = StarforgeGunFire:new()

function StarforgeSonarDart:new(abilityConfig)
  local primary = config.getParameter("altAbility")
  return StarforgeGunFire.new(self, sb.jsonMerge(primary, abilityConfig))
end

function StarforgeSonarDart:init()
  self.cooldownTimer = self.fireTime
  self.pingTimer = 0

  
  local detectConfig = self.pingDetectConfig
  detectConfig.maxRange = self.pingRange
  activeItem.setScriptedAnimationParameter("pingDetectConfig", detectConfig)
  activeItem.setScriptedAnimationParameter("pingLocation", nil)
end

function StarforgeSonarDart:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == "alt"
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and self.pingTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) 
    and status.overConsumeResource("energy", self:energyPerShot()) then

    self:setState(self.fire)
  end

  if self.pingTimer > 0 then
    self.pingTimer = math.max(self.pingTimer - dt, 0)
    if self.pingTimer == 0 then
      self.cooldownTimer = self.pingCooldown
      activeItem.setScriptedAnimationParameter("pingLocation", nil)
    else
      local radius = (self.pingRange + self.pingBandWidth) * ((self.pingDuration - self.pingTimer) / self.pingDuration) - self.pingBandWidth
      activeItem.setScriptedAnimationParameter("pingOuterRadius", radius + self.pingBandWidth)
      activeItem.setScriptedAnimationParameter("pingInnerRadius", math.max(radius, 0))
    end
  end
end

function StarforgeSonarDart:fire()
  self.weapon:setStance(self.stances.fire)

  self:muzzleFlash()

	local beamStart = StarforgeGunFire.firePosition(self)
  local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(self.inaccuracy or 0)), self.pingCenterRange))

	--Do a line collision check on terrain
  local collidePoint = world.lineCollision(beamStart, beamEnd)
  if collidePoint then
    self.pingTimer = self.pingDuration
    local pingLocation = vec2.floor(collidePoint)
    activeItem.setScriptedAnimationParameter("pingLocation", pingLocation)
    animator.playSound("ping")
    
    self:spawnProjectile(collidePoint)
  end

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function StarforgeSonarDart:spawnProjectile(pos)
  local params = sb.jsonMerge(self.projectileParameters, params or {})
  params.power = 0
  params.damageType = "noDamage"
  params.powerMultiplier = activeItem.ownerPowerMultiplier()

  local projectileType = projectileType or self.projectileType
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end
  
  projectileId = world.spawnProjectile(
      projectileType,
      pos,
      activeItem.ownerEntityId(),
      self:aimVector(self.inaccuracy),
      self.trackSourceEntity or false,
      params
    )
  return projectileId
end