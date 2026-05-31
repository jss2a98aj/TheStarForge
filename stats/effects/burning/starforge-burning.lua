local oldInit = init
function init() oldInit()
  message.setHandler("starforge-detonateBurn", function(_, _, delay, damage)
    world.spawnProjectile("starforge-resonatingburn", entity.position(), effect.sourceEntity(), {0, 0}, true, {
      timeToLive = delay,
      power = damage
    })
    effect.expire()
  end)
end