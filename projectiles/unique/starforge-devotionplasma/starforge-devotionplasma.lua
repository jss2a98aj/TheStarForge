require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.controlRotation = config.getParameter("controlRotation")
  self.searchDistance = config.getParameter("searchDistance", 45)
  self.rotationSpeed = 0
end

function update(dt)
	local targets = world.entityQuery(mcontroller.position(), self.searchDistance, {
      withoutEntityId = projectile.sourceEntity(),
      includedTypes = {"creature"},
      order = "nearest"
    })
    
  for _, target in ipairs(targets) do
    if entity.entityInSight(target) and world.entityCanDamage(projectile.sourceEntity(), target) then
      self.aimPosition = world.entityPosition(target)
    end
  end

  if self.aimPosition then
    if self.controlRotation then
      rotateTo(self.aimPosition, dt)
    end
  end
end

function destroy()
  if self.aimPosition then
    activate()
  end
end

function activate()
  local rotation = mcontroller.rotation()
  world.spawnProjectile(
    "energycrystal",
    mcontroller.position(),
    projectile.sourceEntity(),
    {math.cos(rotation), math.sin(rotation)},
    false,
    {
      speed = 50,
      power = projectile.power(),
      powerMultiplier = projectile.powerMultiplier(),
      damageKind = config.getParameter("damageKind", "plasma"),
      processing = config.getParameter("processing", ""),
      periodicActions = {
        {
          time = 0,
          ["repeat"] = false,
          action = "sound",
          options = { "/sfx/gun/pulsecannon_blast1.ogg" }
        },
        {
          time = 0.066,
          ["repeat"] = true,
          action = "particle",
          rotate = true,
          specification = {
            type = "textured",
            animation = "/animations/crystaltrail/crystaltrail.png:0" .. config.getParameter("processing", ""),
            initialVelocity = {0.0, 0.0},
            timeToLive = 0.2,
            destructionAction = "fade",
            destructionTime = 0.2,
            layer = "back",
            position = {0.0, 0.0}
          }
        }
      }
    }
  )

  projectile.processAction(
    {
      action = "projectile",
      inheritDamageFactor = 0,
      type = "redpulsecannonexplosion",
      config = {
        processing = config.getParameter("processing", "")
      }
    }
  )
end

function rotateTo(position, dt)
  local vectorTo = world.distance(position, mcontroller.position())
  local angleTo = vec2.angle(vectorTo)
  if self.controlRotation.maxSpeed then
    local currentRotation = mcontroller.rotation()
    local angleDiff = util.angleDiff(currentRotation, angleTo)
    local diffSign = angleDiff > 0 and 1 or -1

    local targetSpeed = math.max(0.1, math.min(1, math.abs(angleDiff) / 0.5)) * self.controlRotation.maxSpeed
    local acceleration = diffSign * self.controlRotation.controlForce * dt
    self.rotationSpeed = math.max(-targetSpeed, math.min(targetSpeed, self.rotationSpeed + acceleration))
    self.rotationSpeed = self.rotationSpeed - self.rotationSpeed * self.controlRotation.friction * dt

    mcontroller.setRotation(currentRotation + self.rotationSpeed * dt)
  else
    mcontroller.setRotation(angleTo)
  end
end
