require "/scripts/vec2.lua"

function init()
  object.setInteractive(true)
  self.statusEffects = config.getParameter("statusEffectsOnInteract", {})
  if type(self.statusEffects) ~= "table" then
    self.statusEffects = {self.statusEffects}
  end
  self.statusDurations = config.getParameter("statusDurations", {})
  if type(self.statusDurations) ~= "table" then
    self.statusDurations = {self.statusDurations}
  end
  
  --If teleport effect
  self.targetPosition = config.getParameter("targetPosition", entity.position())
  self.targetId = config.getParameter("targetId")
  self.teleportOffset = config.getParameter("teleportOffset", {0, 2.75})
end

function update(dt)
end

function onInteraction(args)
  animator.playSound("applyEffect")
  for x, effect in pairs(self.statusEffects) do
    local duration = self.statusDurations[x]
    self.interactEntity = args.sourceId
    
    world.sendEntityMessage(args.sourceId, "applyStatusEffect", effect, duration)
    
    --If teleport effect
    if effect == "starforge-teleporttoposition" then
      local teleportPosition = self.targetPosition
      if self.targetId then
        local targetEntityId = world.loadUniqueEntity(self.targetId)
        teleportPosition = world.entityPosition(targetEntityId)
      end
      teleportPosition = vec2.add(teleportPosition, self.teleportOffset)
      world.sendEntityMessage(args.sourceId, "starforge-setteleportposition", teleportPosition)
    end
  end
end