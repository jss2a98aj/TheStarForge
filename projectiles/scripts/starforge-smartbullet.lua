require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.targetSpeed = config.getParameter("targetSpeed") or vec2.mag(mcontroller.velocity())
  self.searchDistance = config.getParameter("searchRadius")
  
  self.controlForce = config.getParameter("baseHomingControlForce") * self.targetSpeed

  self.target = config.getParameter("target")

  self.disengageDistance = config.getParameter("disengageDistance")
  
  if config.getParameter("homingStartDelay") ~= nil then
    self.homingEnabled = false
    self.countdownTimer = config.getParameter("homingStartDelay")
  else
	  self.homingEnabled = true
  end
end

function update(dt)
  if self.target then
    if self.homingEnabled == true then
      if world.entityExists(self.target) and world.entityCanDamage(projectile.sourceEntity(), self.target) then
        local targetPos = world.entityPosition(self.target)
        local myPos = mcontroller.position()
        local dist = world.distance(targetPos, myPos)
        if self.disengageDistance then
          local mag = world.magnitude(targetPos, myPos)
          if mag < self.disengageDistance then
            self.homingEnabled = false
          end
        end

        mcontroller.approachVelocity(vec2.mul(vec2.norm(dist), self.targetSpeed), self.controlForce)
      end
    elseif self.countdownTimer then
      self.countdownTimer = math.max(0, self.countdownTimer - dt)
      if self.countdownTimer == 0 then
        self.homingEnabled = true
        self.countdownTimer = nil
      end
    end
    
    --Code for ensuring a constant speed
    if config.getParameter("constantSpeed") == true then
      local currentVelocity = mcontroller.velocity()
      local newVelocity = vec2.mul(vec2.norm(currentVelocity), self.targetSpeed)
      mcontroller.setVelocity(newVelocity)
    end
  end
end
