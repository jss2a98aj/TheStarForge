require "/scripts/vec2.lua"

function init()
  self.movementSpeedToDash = config.getParameter("movementSpeedToDash", 20)
  self.pitchVariance = config.getParameter("pitchVariance", 0.1)
end

function update(dt)
  local velocity = mcontroller.velocity()
  local currentSpeed = vec2.mag(velocity)

  if currentSpeed > self.movementSpeedToDash then
    if not self.firstDashed then
      local direction = velocity[1] < 0 and "Left" or "Right"
      animator.burstParticleEmitter("startDash" .. direction)

      local pitchVariance = (1 + self.pitchVariance) - (math.random() * (self.pitchVariance * 2)) + (pitchIncrease or 0)
      animator.setSoundPitch("startDash", pitchVariance)
      animator.playSound("startDash")
      
      self.firstDashed = true
    end
    animator.resetTransformationGroup("dash")
    animator.rotateTransformationGroup("dash", math.atan(velocity[2], velocity[1]))
    animator.setParticleEmitterActive("dashParticles", true)
  else
    self.firstDashed = nil
    animator.setParticleEmitterActive("dashParticles", false)
  end
end