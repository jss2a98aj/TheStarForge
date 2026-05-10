require "/scripts/vec2.lua"

function init()  
  self.projectileReapActionOnHit = config.getParameter("projectileReapActionOnHit", {})
  self.projectileReapActionOnBreak = config.getParameter("projectileReapActionOnBreak", {})
  
  self.damageParticles = config.getParameter("damageParticles", false)
  self.destroyParticles = config.getParameter("destroyParticles", false)

  self.healthMultiplierForHit = config.getParameter("healthMultiplierForHit", 1)
  self.initialHealth = config.getParameter("health", 100)
  self.hitThreshold = self.initialHealth * self.healthMultiplierForHit * self.healthMultiplierForHit
  self.essenceOnBreak = config.getParameter("healthMultiplierForBreak", 1) * self.initialHealth

  storage.health = storage.health or object.health()
end

function update(dt)
  --If our current health is lower than stored health, we received damage and should burst the damage particle emitter
  if object.health() ~= storage.health then
    if self.damageParticles then
      animator.burstParticleEmitter("damage")
      animator.playSound("damage")
    end
    if self.projectileReapActionOnHit then
      local damageTaken = storage.health - object.health()
      if damageTaken > self.hitThreshold then
        spawnProjectile(self.projectileReapActionOnHit, damageTaken * self.healthMultiplierForHit)
      end
    end
  end
  
  storage.health = object.health()
  
  world.debugPoint(vec2.add(object.position(), config.getParameter("explosionOffset", {0,0})), "red")
end

function die()
  if self.projectileReapActionOnBreak then
    spawnProjectile(self.projectileReapActionOnBreak, self.essenceOnBreak)
  end
  if self.destroyParticles then
	  animator.burstParticleEmitter("destroy")
  end
end

function spawnProjectile(reapActions, damage)
  sb.logInfo("%s", math.max(1, math.floor(damage)))
  actionLoop = {
    action = "loop",
    count = math.max(1, math.floor(damage)),
    body = reapActions
  }
  local projectileConfig = {
    damageTeam = { type = "indiscriminate" },
    onlyHitTerrain = false,
    timeToLive = 0,
    damageRepeatGroup = config.getParameter("damageRepeatGroup", "environment"),
    actionOnReap = {actionLoop}
  }
  world.spawnProjectile("invisibleprojectile", vec2.add(object.position(), config.getParameter("explosionOffset", {0, 0})), entity.id(), {0, 1}, false, projectileConfig)
end