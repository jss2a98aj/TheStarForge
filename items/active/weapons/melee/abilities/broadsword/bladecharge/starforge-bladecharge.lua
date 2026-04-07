require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/weapon.lua"

StarforgeBladeCharge = WeaponAbility:new()

function StarforgeBladeCharge:init()
  StarforgeBladeCharge:reset()

  self.cooldownTimer = 0
end

function StarforgeBladeCharge:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.cooldownTimer == 0 and not self.weapon.currentAbility and not status.resourceLocked("energy") and self.fireMode == "alt" then
    self:setState(self.charge)
  end
end

function StarforgeBladeCharge:charge()
  self.weapon:setStance(self.stances.windup)

  animator.setParticleEmitterActive("bladeCharge", true)
  animator.playSound("charging", -1)

  local windupProgress = windupProgress or 0
  while self.fireMode == "alt" do
    local progressRatio = math.sin(windupProgress / self.chargeTime * 1.57)
    if windupProgress < 1 then
      windupProgress = math.min(1, windupProgress + (self.dt / self.chargeTime))
      
	    local from = self.stances.windup.weaponOffset or {0, 0}
      local to = self.stances.windup.endWeaponOffset or {0, 0}
      self.weapon.weaponOffset = {util.interpolateSigmoid(progressRatio, from[1], to[1]), interp.linear(progressRatio, from[2], to[2])}

      self.weapon.relativeWeaponRotation = util.toRadians(util.lerp(progressRatio, {self.stances.windup.startWeaponRotation, self.stances.windup.weaponRotation}))
      self.weapon.relativeArmRotation = util.toRadians(util.lerp(progressRatio, {self.stances.windup.startArmRotation, self.stances.windup.armRotation}))
    elseif windupProgress == 1 and not self.soundPlaying then
      self.soundPlaying = true
      animator.stopAllSounds("charging")
      animator.playSound("chargedReady")
      animator.playSound("chargedHold", -1)
      animator.setGlobalTag("bladeDirectives", "border=" .. (self.borderSize or 3) .. ";" .. self.chargeBorder .. ";00000000")
    end
    
    --If the weapon has configured aim angle modifiers, multiply the player's aim angle by these modifiers
    if self.maxAimAngleModifier and self.minAimAngleModifier then
      local aimAngle, aimDirection = activeItem.aimAngleAndDirection(-1, activeItem.ownerAimPosition())
      if aimAngle > 0 then
        self.weapon.aimAngle = (aimAngle * self.maxAimAngleModifier * progressRatio) --Multiply by modifier and progressRatio for smooth transitions!
      else
        self.weapon.aimAngle = (aimAngle * self.minAimAngleModifier * progressRatio) --Multiply by modifier and progressRatio for smooth transitions!
      end
    end
    coroutine.yield()
  end
  self.soundPlaying = nil

  animator.stopAllSounds("charging")
  animator.stopAllSounds("chargedHold")

  if windupProgress == 1 and status.overConsumeResource("energy", self.energyUsage) then
    self:setState(self.windup)
  end
end

function StarforgeBladeCharge:windup()
  self.weapon:updateAim()
  --If the weapon has configured aim angle modifiers, multiply the player's aim angle by these modifiers
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(-1, activeItem.ownerAimPosition())
  local windupSwing = {}
  if self.stances.windup.windupSwing ~= false or self.stances.windup.windupSwing ~= 0 then
    local windupSwingValue = self.stances.windup.windupSwing or 0.1
    local fireStance = self.stances.slash
    windupSwing.armRotation = (self.stances.windup.armRotation - fireStance.armRotation) * windupSwingValue
    windupSwing.weaponRotation = (self.stances.windup.weaponRotation - fireStance.weaponRotation) * windupSwingValue
  end
  
  local progress = 0
  util.wait(self.stances.windup.duration * (self.stanceSpeedFactor or 1), function()
    if self.stances.windup.windupSwing ~= false then
      for part, rotation in pairs(windupSwing) do      
        self.weapon["relative" .. part:gsub("^%l", string.upper)] = self.weapon["relative" .. part:gsub("^%l", string.upper)] - (rotation * (self.stances.windup.windupSwing or 0.1) * progress * self.dt)
      end
      progress = math.min(1.0, progress + (self.dt / (self.stances.windup.duration * (self.stanceSpeedFactor or 1))))
    end
  end)

  self:setState(self.slash)
end

function StarforgeBladeCharge:slash()
  self.weapon:setStance(self.stances.slash)
  animator.setGlobalTag("comboDirectives", self.stances.slash.comboDirectives or "")
  self.weapon:updateAim()

  if self.stances.slash.swooshRotation then
    animator.resetTransformationGroup("swooshOffset")
    animator.rotateTransformationGroup("swooshOffset", util.toRadians(self.stances.slash.swooshRotation))
  end
  animator.setParticleEmitterActive("bladeCharge", false)
  animator.setAnimationState("swoosh", self.swooshAnimationState or "fire")
  --Add normal pitch variance to shots
  local pitchVariance = ((self.swingPitchFactor or 1) + (self.pitchVariance or 0.1)) - (math.random() * ((self.pitchVariance or 0.1) * 2)) + (pitchIncrease or 0)
  animator.setSoundPitch("chargedSwing", pitchVariance)
  animator.playSound("chargedSwing")

  local overSwing = {}
  if self.stances.slash.overSwing ~= false or self.stances.slash.overSwing ~= 0 then
    local overSwingValue = self.stances.slash.overSwing or 0.1
    local windupStance = self.stances.windup
    overSwing.armRotation = (self.stances.slash.armRotation - windupStance.armRotation) * overSwingValue
    overSwing.weaponRotation = (self.stances.slash.weaponRotation - windupStance.weaponRotation) * overSwingValue
  end

  local progress = 0
  util.wait(self.stances.slash.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.damageConfig, damageArea)
    
    if self.stances.slash.overSwing ~= false or self.stances.slash.overSwing ~= 0 then
      for part, rotation in pairs(overSwing) do
        local from = self.stances.slash[part]
        local to = self.stances.slash[part] + rotation
      
        self.weapon["relative" .. part:gsub("^%l", string.upper)] = util.toRadians(util.interpolateHalfSigmoid(progress, from, to))
      end
      progress = math.min(1.0, progress + (self.dt / (self.stances.slash.duration * (self.stanceSpeedFactor or 1))))
    end
  end)

  self.cooldownTimer = self.cooldownTime
end

function StarforgeBladeCharge:reset()
  animator.setGlobalTag("bladeDirectives", "")
  animator.setParticleEmitterActive("bladeCharge", false)
  animator.setAnimationState("bladeCharge", "idle")
end

function StarforgeBladeCharge:uninit()
  self:reset()
end
