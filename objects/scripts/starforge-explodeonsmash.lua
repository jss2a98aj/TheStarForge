require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  object.setHealth(25252525)
  self.lastHealth = object.health()
  self.damageTaken = 0
  
  self.regrowTime = config.getParameter("regrowTime", 5)
  storage.regrowTimer = 0
  
  self.proximityScan = config.getParameter("proximityScan")
  self.proximityToDetonate = config.getParameter("proximityToDetonate")
  self.proximityShakeConfig = config.getParameter("proximityShakeConfig")

  self.soundPlaying = false
  
  self.objectCenter = {-object.direction(), 0}

  animator.setAnimationState("activeState", (storage.regrowTimer > 0) and "inactive" or "active")
end

function update(dt)
  storage.regrowTimer = math.max(0, storage.regrowTimer - dt)
  if storage.regrowTimer == 0 and animator.animationState("activeState") == "inactive" then
  	animator.setAnimationState("activeState", "regrow")
  end
  
  animator.resetTransformationGroup("body")
  if self.proximityScan and animator.animationState("activeState") == "active" then
    local measurePos = vec2.add(entity.position(), vec2.add(vec2.add(self.objectCenter, config.getParameter("floorOffset", {0, 0})), {-0.5, 2}))
    world.debugPoint(measurePos, "red")
    local target = world.entityQuery(measurePos, self.proximityScan, {
      withoutEntityId = entity.id(),
      includedTypes = {"player"},
      order = "nearest"
    })[1]
	
    if target then
      local dist = world.magnitude(measurePos, world.entityPosition(target))
    
      if self.proximityToDetonate and dist < self.proximityToDetonate then
        explode()
      end

      if not self.soundPlaying and dist < self.proximityScan then
        self.soundPlaying = true
        animator.playSound("proximitySound", -1)
      elseif dist > self.proximityScan then
        self.soundPlaying = false
        animator.stopAllSounds("proximitySound")
      end
    
      if self.proximityShakeConfig then
        local distFactor = math.max(0, 1 - (dist / self.proximityScan))
        animator.setSoundPitch("proximitySound", 1 + distFactor)
        local cycle = (self.proximityShakeConfig.cycle / (2 * math.pi))
        self.shakeTimer = (self.shakeTimer or 0) + (dt * distFactor) % (cycle * 2)
      
        --local floorPoint = vec2.mul(animator.partPoint("base", "rotationCentre"), -1) --vec2.add(vec2.sub(world.lineTileCollisionPoint(entity.position(), vec2.add(entity.position(), {0, -5}))[1], entity.position()), self.proximityShakeConfig.floorOffset or {0, 0})
        
        --floorPoint = vec2.add(floorPoint, config.getParameter("floorOffset", {0, 0})) --{1.5, -2})
        --[[if object.direction() > 0 then
          floorPoint = vec2.add(floorPoint, {1.5, -2})
        else
          floorPoint = vec2.add(floorPoint, {-1.5, -2})
        end]]
        
        --floorPoint = vec2.mul(floorPoint, {object.direction(), 0})

        self.currentRotation = self.proximityShakeConfig.amplitude * math.sin(self.shakeTimer / cycle)
      end
    end
  end
  animator.rotateTransformationGroup("body", self.currentRotation or 0, vec2.add(self.objectCenter, config.getParameter("floorOffset", {0, 0})))
  
  if self.damageTaken > config.getParameter("damageToBurst", 5) and animator.animationState("activeState") == "active" then
    explode()
  end
  
  if object.health() < self.lastHealth then
    takeDamage(self.lastHealth - object.health())
  end
  self.lastHealth = object.health()
  --world.debugText("Regrow Time: " .. storage.regrowTimer, vec2.add(entity.position(), {0, 5}), "yellow")
end

function takeDamage(damage)
  if animator.animationState("activeState") == "active" then
    self.damageTaken = self.damageTaken + damage
  end
  
  animator.playSound("takeDamage")
  animator.burstParticleEmitter("takeDamage")
  object.setHealth(25252525)
end

function explode()
  self.damageTaken = 0
  storage.regrowTimer = self.regrowTime

  local objectCenter = vec2.add(object.position(), config.getParameter("projectileSpawnOffset", {0, 0}))

  animator.setAnimationState("activeState", "inactive")
  animator.playSound("burst")
  animator.burstParticleEmitter("burst")
  
  local params = sb.jsonMerge(config.getParameter("burstProjectileParameters", {}), {})
  local projectileType = config.getParameter("burstProjectileType", "standardbullet")
  if type(projectileType) ~= "table" then
    projectileType = {projectileType}
  end
  params.powerMultiplier = world.threatLevel()
  
  for _, projectile in ipairs(projectileType) do
    projectileId = world.spawnProjectile(
        projectile,
        objectCenter,
        entity.id(),
        {0, -1},
        false,
        params
      )
  end
end