function init()
  self.fadeOut = config.getParameter("fadeOut", false)
  self.deathEffects = config.getParameter("deathEffects", {})
  self.baseEffectDuration = effect.duration()
end

function update(dt)
  local progress = effect.duration() / self.baseEffectDuration
  local fade = toHex(255 - math.floor(255 * (self.fadeOut and 1 - progress or progress)))
  effect.setParentDirectives("?multiply=FFFFFF".. fade)
  
  world.debugText("Fade = %s", fade, mcontroller.position(), "red")
end

function toHex(num)
  local hex = string.format("%X", math.floor(num + 0.5))
  if num < 16 then hex = "0"..hex end
  return hex
end

function onExpire()
  if self.fadeOut then
    if self.deathEffects and self.deathEffects.hideDeath then
      if world.entityType(entity.id()) == "npc" then
        world.callScriptedEntity(entity.id(), "npc.setDeathParticleBurst", nil)
        world.callScriptedEntity(entity.id(), "npc.setDropPools", {})
      elseif world.entityType(entity.id()) == "monster" then
        world.callScriptedEntity(entity.id(), "monster.setDeathParticleBurst", nil)
        world.callScriptedEntity(entity.id(), "monster.setDropPool", "empty")
      end
    end
    mcontroller.controlModifiers({
        facingSuppressed = true,
        movementSuppressed = true
      })
    status.setResource("health", 0)
  end
end

--/spawnitem antidote 1 '{"description":"Use this to test a status effect.","shortdescription":"Test Potion","maxstack":100,"effects":[["starforge-fadeoutnpc"]]}'