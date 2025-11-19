require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"

function init()  
  --Loading stats from config file into self
  self.maxHearts = config.getParameter("maxHearts", 3)
  self.healthPerHeartFactor = config.getParameter("healthPerHeartFactor", 1)
  self.uiOffset = config.getParameter("uiOffset", {0, 3})
  
  --Initial stats
  self.crouchOffset = {0, 0}
  self.mainOffset = {0, 0}
  self.currentHearts = math.floor(status.resource("damageAbsorption") / status.resourceMax("health") / self.healthPerHeartFactor)
  self.lastHearts = 0
  self.lastAbsorption = status.resource("damageAbsorption")
  self.totalAbsorption = 0

  refreshDuration()
  animator.resetTransformationGroup("ui")
  animator.setAnimationState("ui", "grow")
end

function update(dt)
  animator.resetTransformationGroup("ui")
  --Code for correcting animation offset for crouching
  self.mainOffset = vec2.add(vec2.sub(world.entityMouthPosition(entity.id()), mcontroller.position()), self.uiOffset)
  animator.translateTransformationGroup("ui", self.mainOffset)
    
  if self.currentHearts > 0 then
    if effect.duration() > 1 then
      refreshDuration()
    end
    effect.modifyDuration(dt)

    local currentAbsorption = status.resource("damageAbsorption")
    
    --Check if we got hit recently by comparing current damage absorption to that of last frame
    if currentAbsorption < self.lastAbsorption then
      takeHit(self.lastAbsorption - currentAbsorption)
    end

    self.lastAbsorption = status.resource("damageAbsorption")
  else
    effect.expire()
  end
end

function refreshDuration()
  local heartsToAdd = math.ceil(effect.duration() * 0.1)
  effect.modifyDuration(0.5 - effect.duration())
  modifyHearts(heartsToAdd)
end

function modifyHearts(heartsToAdd)
  self.currentHearts = math.min(self.maxHearts, self.currentHearts + heartsToAdd)
  self.totalAbsorption = self.currentHearts * (status.resourceMax("health") * self.healthPerHeartFactor)
  status.setResource("damageAbsorption", self.totalAbsorption)
  animator.setGlobalTag("count", self.currentHearts)
  if self.currentHearts > self.lastHearts then
    animator.setAnimationState("ui", "grow")
  else
    animator.setAnimationState("ui", "break")
  end
  self.lastHearts = self.currentHearts
end

function takeHit()
  animator.setAnimationState("ui", "break")
  animator.playSound("takeHit")
  animator.burstParticleEmitter("takeHit")

  local newHearts = math.floor(status.resource("damageAbsorption") / status.resourceMax("health") / self.healthPerHeartFactor)
  modifyHearts(newHearts - self.currentHearts)
end

function uninit()
end

function onExpire()
  status.setResource("damageAbsorption", 0)
end