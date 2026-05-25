require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/starforge-util.lua"
require "/items/active/weapons/ranged/starforge-gunfire.lua"

local oldInit = StarforgeGunFire.init or function() end
function StarforgeGunFire:init()
  animator.setGlobalTag("target", self.noTargetTag or "?replace;c67cee=c67cee00")
  activeItem.setScriptedAnimationParameter("entityMarker", self.entityMarker)

  self.markLingerTimer = 0
  
  oldInit(self)
end

local oldUpdate = StarforgeGunFire.update or function() end
function StarforgeGunFire:update(dt, fireMode, shiftHeld)
  local newTarget = self:findTarget()
  self.markLingerTimer = math.max(0, (self.markLingerTimer or 0) - dt)
  if newTarget and self.target ~= newTarget and world.entityExists(newTarget) then
    self.target = newTarget
    if not self.muteSounds then
      animator.playSound("targetAcquired")
    end

    self.markLingerTimer = self.markLingerTime or 1
    animator.setGlobalTag("target", self.targetLockedTag or "")
    activeItem.setScriptedAnimationParameter("entities", {self.target})
  elseif self.target and (not world.entityExists(self.target) or (not newTarget and self.markLingerTimer == 0)) then
    self.target = nil
    
    animator.setGlobalTag("target", self.noTargetTag or "?replace;c67cee=c67cee00")
    activeItem.setScriptedAnimationParameter("entities", {})
    if not self.muteSounds then
      animator.playSound("disengage")
    end
  end
  
  oldUpdate(self, dt, fireMode, shiftHeld)
end

local oldFireProjectile = StarforgeGunFire.fireProjectile or function() end
function StarforgeGunFire:fireProjectile(projectileType, params, burstNumber) 
  local newParams = {target = self.target}
  oldFireProjectile(self, projectileType, newParams, burstNumber)
end

function StarforgeGunFire:findTarget()
  local nearEntities = world.entityQuery(activeItem.ownerAimPosition(), self.targetQueryDistance or 0, { includedTypes = {"creature"} })
  nearEntities = util.filter(nearEntities, function(entityId)
    if not world.entityCanDamage(activeItem.ownerEntityId(), entityId) then
      return false
    end

    if world.lineTileCollision(self:firePosition(), world.entityPosition(entityId)) then
      return false
    end

    return true
  end)

  if #nearEntities > 0 then
    return nearEntities[1]
  else
    return false
  end
end
