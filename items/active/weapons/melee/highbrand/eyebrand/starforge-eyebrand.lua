require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

starforge_eyeBrand_init = init
function init() starforge_eyeBrand_init()
  self.eyes = config.getParameter("eyes", {})
  for eye, config in pairs(self.eyes) do
    config.blinkTimer = util.randomInRange(config.blinkTime)
    config.twitchTimer = util.randomInRange(config.twitchTime)
  end
end

starforge_eyeBrand_update = update
function update(dt, fireMode, shiftHeld) starforge_eyeBrand_update(dt, fireMode, shiftHeld)
  for eye, config in pairs(self.eyes) do
    config.blinkTimer = math.max(0, config.blinkTimer - dt)
    if config.blinkTimer == 0 then
      animator.setAnimationState(eye, "blink")
      config.blinkTimer = util.randomInRange(config.blinkTime)
    end

    config.twitchTimer = math.max(0, config.twitchTimer - dt)
    if config.twitchTimer == 0 then
      local twitchOffset = vec2.rotate({math.random() * config.twitchMagnitude, 0}, math.random() * 2 * math.pi)
      animator.resetTransformationGroup(eye)
      animator.translateTransformationGroup(eye, twitchOffset)
      config.twitchTimer = util.randomInRange(config.twitchTime)
    end
  end
end