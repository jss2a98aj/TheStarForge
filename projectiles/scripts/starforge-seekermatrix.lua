require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.actionOnArm = config.getParameter("actionOnArm", {})

  self.detectionRange = config.getParameter("detectionRange", 10)

  self.armedParticleInterval = config.getParameter("armedParticleInterval", 10)
  self.armedParticleEmissionRate = 1 / config.getParameter("armedParticleEmissionRate", 10)
  self.particleTimer = self.armedParticleEmissionRate
  self.armedParticleSpecification = config.getParameter("armedParticleSpecification")

  self.seekerProjectileCooldown = config.getParameter("seekerProjectileCooldown", 1)
  self.seekerProjectileCooldownTimer = 0
  self.seekerProjectileCount = config.getParameter("seekerProjectileCount", 1)
  self.seekerProjectileType = config.getParameter("seekerProjectileType", "standardbullet")
  self.seekerProjectileConfig = config.getParameter("seekerProjectileConfig", {})
  self.minimumSpeed = config.getParameter("minimumSpeed", 10)

  local windupFrames = config.getParameter("windupFrames")
  self.armingTimer = windupFrames and (windupFrames * config.getParameter("animationCycle", 1)) or nil

  world.entityQuery(entity.position(), self.detectionRange * 10, {
    withoutEntityId = entity.id(),
    includedTypes = {"projectile"},
    callScript = "terminate",
    callScriptArgs = {config.getParameter("projectileName")}
  })
end

function update(dt)
  if not self.armingTimer or self.armingTimer == 0 then
    if self.armingTimer then
      for _, action in ipairs(self.actionOnArm) do 
        projectile.processAction(action)
      end
      self.armingTimer = nil
    end

    self.seekerProjectileCooldownTimer = math.max(0, self.seekerProjectileCooldownTimer - dt)
    if self.seekerProjectileCooldownTimer == 0 then
      local target = seekTarget()
      if target then
        spawnSeeker(target)
        self.seekerProjectileCooldownTimer = self.seekerProjectileCooldown
      end
    end

    if self.armedParticleSpecification then
      updateParticles(dt)
    end
  else
    self.armingTimer = math.max(0, self.armingTimer - dt)
  end
end

function spawnSeeker(entityId)
  local projectileConfig = sb.jsonMerge({
      targetId = entityId
    }, self.seekerProjectileConfig)
  local randAngle = math.random() * 360
  for i = 1, self.seekerProjectileCount do 
    local angle = randAngle + ((360 / self.seekerProjectileCount) * i)
    projectile.processAction({
        action = "projectile",
        type = self.seekerProjectileType,
        config = projectileConfig,
        angle = angle,
        fuzzAngle = 15,
        inheritDamageFactor = 1 / self.seekerProjectileCount,
      })
  end
end 

function updateParticles(dt)
  self.particleTimer = math.max(0, self.particleTimer - dt)
  if self.particleTimer == 0 then
    for i = 1, self.armedParticleInterval do 
      local offset = calculateOffset(i)
      local newSpecification = sb.jsonMerge({
          position = offset
        }, self.armedParticleSpecification)
      
      projectile.processAction({
          action = "particle",
          specification = newSpecification
        })
    end
    self.particleTimer = self.armedParticleEmissionRate
  end
end

function terminate(name)
  if name == config.getParameter("projectileName") then
    projectile.die()
  end
end

function calculateOffset(index)
  local intervalStep = (math.pi * 2) / self.armedParticleInterval
  local offsetPoint = vec2.rotate({self.detectionRange, 0}, index * intervalStep + mcontroller.rotation())
  local lineCollision = world.lineTileCollisionPoint(entity.position(), vec2.add(entity.position(), offsetPoint))
  if lineCollision then
    offsetPoint = vec2.sub(entity.position(), lineCollision[1])
  end
  offsetPoint = vec2.rotate(offsetPoint, -mcontroller.rotation() + (lineCollision and math.pi or 0))
  return offsetPoint
end

function seekTarget()
  local targets = world.entityQuery(mcontroller.position(), self.detectionRange, {
    withoutEntityId = entity.id(),
    includedTypes = {"projectile"},
    order = "nearest"
  })
  
  targets = util.filter(targets, function(targetId)
    return world.entityExists(targetId)
      and world.magnitude(world.entityPosition(targetId), entity.position()) <= self.detectionRange
      and world.entityName(targetId) ~= self.seekerProjectileType
      and world.entityName(targetId) ~= config.getParameter("projectileName")
      and vec2.mag(world.entityVelocity(targetId) or {0, 0}) > self.minimumSpeed    --why to fix
      and not world.lineTileCollision(entity.position(), world.entityPosition(targetId)) 
      and (world.entityDamageTeam(targetId).type == world.entityDamageTeam(entity.id()).type)
  end)

  return targets[1]
end