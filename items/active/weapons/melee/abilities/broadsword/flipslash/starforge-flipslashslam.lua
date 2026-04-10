require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

StarforgeFlipSlashSlam = WeaponAbility:new()

function StarforgeFlipSlashSlam:init()
  self.cooldownTimer = self.cooldownTime
end

function StarforgeFlipSlashSlam:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility
     and self.cooldownTimer == 0
     and self.fireMode == "alt"
     and self:inGravity()
     and not status.statPositive("activeMovementAbilities")
     and status.overConsumeResource("energy", self.energyUsage) then

      if self:nearGround() then
        self:setState(self.windup)
      else
        self:setState(self.slam)
      end
  end
end

function StarforgeFlipSlashSlam:windup()
  self.weapon:setStance(self.stances.windup)

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  util.wait(self.stances.windup.duration, function(dt)
      mcontroller.controlCrouch()
    end)

  self:setState(self.flip)
end

function StarforgeFlipSlashSlam:flip()
  self.weapon:setStance(self.stances.flip)
  self.weapon:updateAim()

  if self.stances.flip.swooshRotation then
    animator.resetTransformationGroup("swooshOffset")
    animator.rotateTransformationGroup("swooshOffset", util.toRadians(self.stances.flip.swooshRotation))
  end
  animator.setAnimationState("swoosh", "flip")
  animator.playSound(self.fireSound or "flipSlash")
  animator.setParticleEmitterActive("flipParticles", true)

  self.flipTime = self.rotations * self.rotationTime
  self.flipTimer = 0

  self.jumpTimer = self.jumpDuration

  while self.flipTimer < self.flipTime do
    self.flipTimer = self.flipTimer + self.dt

    mcontroller.controlParameters(self.flipMovementParameters)

    if self.jumpTimer > 0 then
      self.jumpTimer = self.jumpTimer - self.dt
      mcontroller.setVelocity({self.jumpVelocity[1] * self.weapon.aimDirection, self.jumpVelocity[2]})
    end

    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)

    mcontroller.setRotation(-math.pi * 2 * self.weapon.aimDirection * (self.flipTimer / self.rotationTime))

    coroutine.yield()
  end

  animator.setAnimationState("swoosh", "idle")
  mcontroller.setRotation(0)
  animator.setParticleEmitterActive("flipParticles", false)
  self:setState(self.slam)
end

function StarforgeFlipSlashSlam:slam()
  self.weapon:setStance(self.stances.windup)
  util.wait(self.slamDelay)

  self.weapon:setStance(self.stances.slam)
  self.weapon:updateAim()

  animator.playSound("slamFall")

  if self.stances.flip.swooshRotation then
    animator.resetTransformationGroup("swooshOffset")
    animator.rotateTransformationGroup("swooshOffset", util.toRadians(self.stances.flip.swooshRotation))
  end
  animator.setAnimationState("swoosh", "slam")

  local lastSlamPosition = self:slamPosition()
  util.wait(self.stances.slam.duration, function(dt)
    if self:inGravity() then
      local damageArea = partDamageArea("swoosh")
      self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)

      mcontroller.addMomentum({self.slamVelocity[1] * self.weapon.aimDirection, self.slamVelocity[2]})
      local newSlamPosition = self:slamPosition()
      if world.lineTileCollision(lastSlamPosition, newSlamPosition) then
        local params = copy(self.projectileParameters)
        params.powerMultiplier = activeItem.ownerPowerMultiplier()
        params.power = params.power * config.getParameter("damageLevelMultiplier")

        local impactPoint = lastSlamPosition
        local collision = world.lineTileCollisionPoint(mcontroller.position(), impactPoint)
        if collision then
          impactPoint = collision[1] 
        end
        
        world.spawnProjectile(self.projectileType, impactPoint, activeItem.ownerEntityId(), {mcontroller.facingDirection() * self.slamAimVec[1], self.slamAimVec[2]}, false, params)
        mcontroller.setVelocity(vec2.mul(vec2.norm(world.distance(self:slamPosition(), impactPoint)), -self.bounceVelocity))
        return true
      end
      lastSlamPosition = newSlamPosition
    end

    if mcontroller.onGround() then return true end

    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)

  status.clearPersistentEffects("weaponMovementAbility")

  animator.setAnimationState("swoosh", "idle")
  self.cooldownTimer = self.cooldownTime
  
  util.wait(self.winddownTime, function(dt)
    end)
end

function StarforgeFlipSlashSlam:slamPosition()
  return vec2.add(activeItem.handPosition(animator.partPoint("blade", "groundSlamPoint")), mcontroller.position())
end

function StarforgeFlipSlashSlam:nearGround()
  local grounded = mcontroller.onGround()
  if world.lineTileCollision(mcontroller.position(), vec2.add(mcontroller.position(), {0, -5})) then
    grounded = true
  end
  return grounded
end


function StarforgeFlipSlashSlam:inGravity()
  return math.abs(world.gravity(mcontroller.position())) > 0
end

function StarforgeFlipSlashSlam:uninit()
  status.clearPersistentEffects("weaponMovementAbility")
  animator.setAnimationState("swoosh", "idle")
  mcontroller.setRotation(0)
  animator.setParticleEmitterActive("flip", false)
end
