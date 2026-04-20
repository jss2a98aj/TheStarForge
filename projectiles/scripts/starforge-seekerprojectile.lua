require "/scripts/vec2.lua"

function init()
  self.startSpeed = vec2.mag(mcontroller.velocity())
  self.baseControlForce = config.getParameter("baseHomingControlForce", 1)
  self.lifeFactor = projectile.timeToLive() * config.getParameter("timeToLiveFactor", 0.25)
  self.lifeTimer = 0

  self.targetId = config.getParameter("targetId")

  updateStats()
end


function update(dt)
  self.lifeTimer = math.min(self.lifeFactor, self.lifeTimer + dt)
  updateStats()
  mcontroller.approachVelocity(vec2.mul(vec2.norm(self.targetDirection), self.currentSpeed), self.controlForce)
end

function updateStats()
  if self.targetId and world.entityExists(self.targetId) then
    self.targetPosition = world.entityPosition(self.targetId)
    local dist = world.distance(self.targetPosition, mcontroller.position())
    self.targetDirection = vec2.norm(dist)
    self.targetSpeed = math.max(math.max(self.targetSpeed or 0, vec2.mag(world.entityVelocity(self.targetId))), self.startSpeed)
  end
  self.currentSpeed = self.startSpeed + (self.lifeTimer / self.lifeFactor) * (self.targetSpeed - self.startSpeed)
  self.controlForce = self.baseControlForce * self.currentSpeed
end