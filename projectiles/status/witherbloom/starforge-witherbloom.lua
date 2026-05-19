require "/scripts/vec2.lua"

function init()
  self.parentEntity = nil
  self.hasParentEntity = false
  
  self.wasKilled = false
  self.killSourceEntity = nil
  self.projectileSpawned = false
  
  message.setHandler("starforge-blossom", function(_, _, delay, sourceEntity)
    projectile.setTimeToLive(delay)
    
    self.killSourceEntity = sourceEntity
    self.wasKilled = true
  end)
end

function update(dt)
  if self.hasParentEntity then
    if not world.entityExists(self.parentEntity) then
      projectile.die()
      self.hasDied = true
    end
  end

  if not self.hasDied then
    projectile.setTimeToLive(1)
  end
end

function setParentEntity(entityId)
  self.parentEntity = entityId
  self.hasParentEntity = true
end

function setDamage(damage)
  projectile.setPower(damage)
end

function kill()
  projectile.die()
  self.hasDied = true
end

function blossom()
  for _, action in ipairs(config.getParameter("actionOnBlossom", {})) do 
    projectile.processAction(action)
  end
  projectile.die()
  self.hasDied = true
end