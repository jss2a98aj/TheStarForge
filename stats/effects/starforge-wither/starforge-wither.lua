require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  animator.setParticleEmitterOffsetRegion("decay", mcontroller.boundBox())
  animator.setParticleEmitterActive("decay", true)
  effect.setParentDirectives(config.getParameter("directive"))

  --Check for damage taken in the init() step to ensure that damage taken before the status was applied won't get calculated for the damage increase
  local damageNotifications, nextStep = status.damageTakenSince(self.queryDamageSince)
  self.queryDamageSince = nextStep
  
  --Determine the size of the afflicted target to calculate how many blooms should spawn
  self.entitySize = 1
  local boundBox = mcontroller.boundBox()
  for i, coord in ipairs(boundBox) do
    if coord > self.entitySize then
      self.entitySize = coord
    end
  end
  self.maximumBlooms = self.entitySize / config.getParameter("sizeToBloomFactor", 1)

  self.totalActiveTime = 0
  self.bloomProjectileType = config.getParameter("bloomProjectileType", "standardbullet")
  self.timeBetweenBlooms = config.getParameter("timeBetweenBlooms", {1, 2})
  self.damageMultiplierPerBloom = config.getParameter("damageMultiplierPerBloom", 0.05)
  self.bonusDamageKind = config.getParameter("bonusDamageKind", "starforge-wither")
  self.bloomTimer = randomFloat(self.timeBetweenBlooms) * 0.5
  self.blooms = {}
  
  animator.playSound("loop", -1)

  message.setHandler("starforge-blossom", function(_, _, delay)
	  effect.modifyDuration(delay - effect.duration())
  end)
end

function update(dt)
  self.bloomTimer = math.max(0, self.bloomTimer - dt)
  if self.bloomTimer == 0 and #self.blooms < self.maximumBlooms then
	  createBloom(self.bloomProjectileType)

    self.bloomTimer = randomFloat(self.timeBetweenBlooms)
  end

  local damageNotifications, nextStep = status.damageTakenSince(self.queryDamageSince)
  self.queryDamageSince = nextStep
  
  if self.canMultiplyDamage and #self.blooms > 0 then
    for _, notification in ipairs(damageNotifications) do
      if notification.healthLost > 1 then
        local damageRequest = {}
        damageRequest.damageType = "IgnoresDef"
        damageRequest.damage = notification.damageDealt * (#self.blooms * self.damageMultiplierPerBloom)
        damageRequest.damageSourceKind = self.bonusDamageKind or notification.damageSourceKind
        damageRequest.sourceEntityId = notification.sourceEntityId
        status.applySelfDamageRequest(damageRequest)
      end
    end
  end

  --If the afflicted target died while the effect is active, create the death projectiles
  if not status.resourcePositive("health") then
    effect.setParentDirectives(config.getParameter("deathDirective"))
	  blossom()
  end
  
  --world.debugText(sb.print(entity.entityType()), vec2.add(mcontroller.position(), {0, 0}), "yellow")
  world.debugText(sb.print("Damage Multiplier: " .. (#self.blooms * self.damageMultiplierPerBloom)), vec2.add(mcontroller.position(), {0, -1}), "yellow")
  world.debugText(sb.print("Size: " .. self.entitySize), vec2.add(mcontroller.position(), {0, -2}), "yellow")
  
  self.canMultiplyDamage = true
end

function createBloom(bloomType)
  local boundBox = mcontroller.boundBox()
  local sector = math.random(1, 4)
  local offset = {0, 0}
  
  --Choose a random quadrant of the boundbox to spawn the blob in
  if sector == 1 then
    offset = {math.random() * boundBox[1], math.random() * boundBox[2]}
  elseif sector == 2 then
    offset = {math.random() * boundBox[3], math.random() * boundBox[4]}
  elseif sector == 3 then
    offset = {math.random() * boundBox[1], math.random() * boundBox[4]}
  elseif sector == 4 then
    offset = {math.random() * boundBox[3], math.random() * boundBox[2]}
  end

  local projectileId = world.spawnProjectile(bloomType, vec2.add(mcontroller.position(), offset), entity.id(), vec2.rotate({1, 0}, math.random() * math.pi * 2), true)
  world.callScriptedEntity(projectileId, "setParentEntity", entity.id()) --Set the projectile's parent entity so it will correctly destroy itself if the target dies
  
  table.insert(self.blooms, projectileId)
end

function blossom()
  if not self.blossomed then
    for i, bloom in ipairs(self.blooms) do
      if world.entityExists(bloom) then
        world.callScriptedEntity(bloom, "blossom")
      end
    end
    self.blossomed = true
  end
end

function randomFloat(range)
  local min = range[1]
  local max = range[2]
  return math.random() * (max - min) + min
end

function uninit()
  for i, bloom in ipairs(self.blooms) do
    if world.entityExists(bloom) then
      world.callScriptedEntity(bloom, "kill")
    end
  end
end