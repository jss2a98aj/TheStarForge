require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.seekSpeed = config.getParameter("seekSpeed", 30)
  self.triggered = config.getParameter("triggered", false)
  self.targets = config.getParameter("targets")
  if not self.targets then projectile.die() end
end

function update(dt)
  if self.targets and #self.targets > 0 then
    if self.triggered then
      seekTarget()
    end
  else
    projectile.die()
  end
end

function hit(entityId)
  local targetIndex = contains(self.targets, entityId)
  if targetIndex then
    table.remove(self.targets, targetIndex)
    local projectileConfig = sb.jsonMerge({
        seekSpeed = self.seekSpeed,
        targets = self.targets,
        triggered = true,
        damageKind = "nodamage",
        movementSettings = {
          collisionEnabled = false
        },
        chainProjectileConfig = config.getParameter("chainProjectileConfig")
      }, config.getParameter("chainProjectileConfig", {}))
    if #self.targets > 0 then
      projectile.processAction({
          action = "projectile",
          type = config.getParameter("chainProjectile"),
          config = projectileConfig,
          angle = 0,
          inheritDamageFactor = 1,
        })
    end
    projectile.die()
  end
end

function trigger()
  self.triggered = true
end

function setTargets(targets)
  self.targets = targets
end

function seekTarget()
  self.targets = util.filter(self.targets, function(targetId)
    return targetId ~= entityId and world.entityExists(targetId)
  end)
  table.sort(self.targets, function(a,b)
    return world.magnitude(mcontroller.position(), world.entityPosition(a)) < world.magnitude(mcontroller.position(), world.entityPosition(b))
  end)

  -- change direction to the closest target in the list
  if #self.targets > 0 then
    local newTarget = self.targets[1]
    local direction = vec2.norm(world.distance(world.entityPosition(newTarget), mcontroller.position()))
    mcontroller.setVelocity(vec2.mul(direction, self.seekSpeed))
  end
end
