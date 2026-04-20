require "/scripts/util.lua"
require "/scripts/status.lua"

-- Melee primary ability
StarforgeDeployShield = WeaponAbility:new()

function StarforgeDeployShield:init()
  self.cooldownTimer = self.cooldownTime
  self.retaliationCooldownTimer = 0

  self.active = false
  self.activeTimer = 0
  
  self.shieldHealth = self.baseShieldHealth * root.evalFunction("shieldLevelMultiplier", config.getParameter("level", 1))
	animator.setAnimationState("shield", "off")
	activeItem.setItemShieldPolys({})
	activeItem.setItemDamageSources({})
	status.clearPersistentEffects("broadswordParry")
end

-- Ticks on every update regardless if this is the active ability
function StarforgeDeployShield:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  self.retaliationCooldownTimer = math.max(0, self.retaliationCooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and fireMode == "alt"
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    if self.active then
      self:setState(self.deactivateShield)
    else
      self:setState(self.activateShield)
    end
  end


  if self.active then
    if status.overConsumeResource("energy", self.energyUsage * self.dt) then
      world.debugText("Shield Health: %s", status.stat("shieldHealth") * status.resource("shieldStamina"), vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset)), "red")
      if self.damageListener then self.damageListener:update() end
      self.activeTimer = self.activeTimer + self.dt
      mcontroller.controlModifiers({runningSuppressed = self.walkWhileActive})
    else
      self:setState(self.deactivateShield)
    end
  end
end

function StarforgeDeployShield:activateShield()
	animator.setAnimationState("shield", "activate")
	animator.playSound("activateShield")
	
	local shieldPoly = animator.partPoly("shield", "shieldPoly")
	activeItem.setItemShieldPolys({shieldPoly})
	
  self.damageListener = damageListener("damageTaken", function(notifications)
    for _, notification in pairs(notifications) do
      if notification.hitType == "ShieldHit" then
        self:processDamage(notification)
      end
    end
  end)
	
	--Sets up the knockback for enemies running into the shield
	if self.knockback and self.knockback > 0 then
		local knockbackDamageSource = {
      poly = shieldPoly,
      damage = 0,
      damageType = "Knockback",
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      knockback = self.knockback,
      rayCheck = true,
      damageRepeatTimeout = 0.25
		}
		activeItem.setItemDamageSources({ knockbackDamageSource })
	end
	
	--Rendering the shield health bar
	status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth}})

	self.active = true
  self.lastStamina = status.resource("shieldStamina")
  self.activeTimer = 0
	self.cooldownTimer = self.cooldownTime
end

function StarforgeDeployShield:processDamage(notification)
  local percentDamage = self.lastStamina - status.resource("shieldStamina")
  if status.resource("shieldStamina") ~= 0 then
    status.setResource("shieldStamina", math.max(self.lastStamina, status.resource("shieldStamina")))
  end
  local elementalStat = root.elementalResistance(notification.damageSourceKind)
  local resistance = self.shieldStats[elementalStat] or 0
  local adjustedPercentDamage = percentDamage - (percentDamage * resistance)
  status.modifyResource("shieldStamina", -adjustedPercentDamage)

  if self.projectileType and self.retaliationCooldownTimer == 0 then
    --Projectile parameters
    local params = copy(self.projectileParameters)
    params.power = self.baseDamage * config.getParameter("damageLevelMultiplier")
    params.powerMultiplier = activeItem.ownerPowerMultiplier()
    
    --Projectile spawn code
    local position = vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("blade", "projectilePoint")))
    local aim = self.weapon.aimAngle
    if not world.lineTileCollision(mcontroller.position(), position) then
      world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {mcontroller.facingDirection() * math.cos(aim), math.sin(aim)}, false, params)
      animator.playSound("shieldBurst")
      animator.burstParticleEmitter("burst")
      self.retaliationCooldownTimer = self.retaliationCooldownTime
    end
  end

  if status.resourcePositive("shieldStamina") then
    animator.playSound("block")
    animator.setAnimationState("shield", "block")
  else
    animator.playSound("break")
    self:setState(self.deactivateShield)
  end

  self.lastStamina = status.resource("shieldStamina")
  return
end


function StarforgeDeployShield:deactivateShield()
	animator.playSound("deactivateShield")
	animator.setAnimationState("shield", "deactivate")
	activeItem.setItemShieldPolys({})
	activeItem.setItemDamageSources({})
	status.clearPersistentEffects("broadswordParry")

  self.lastStamina = nil
	self.active = false
	self.cooldownTimer = self.cooldownTime
end

function StarforgeDeployShield:uninit()
end
