function init()
  self.npcEffects = (world.entityType(entity.id()) == "npc") and config.getParameter("npcEffects") or false
end

function update()
  if self.npcEffects and self.npcEffects.danceAtTime and effect.duration() < self.npcEffects.danceAtTime[2] then
    world.callScriptedEntity(entity.id(), "npc.dance", self.npcEffects.danceAtTime[1])
    if self.npcEffects.dialogue then
      world.callScriptedEntity(entity.id(), "npc.say", self.npcEffects.dialogue)
    end
  end
end

function onExpire()
  if self.npcEffects and self.npcEffects.hideDeath then
    world.callScriptedEntity(entity.id(), "npc.setDeathParticleBurst", nil)
    world.callScriptedEntity(entity.id(), "npc.setDropPools", {})
  end
  status.addEphemeralEffect(config.getParameter("effectOnExpire", "beamout"))
end