function init()
  world.spawnStagehand(entity.position(), "starforge-spawnmonster", {
    monsterConfigs = config.getParameter("monsterConfigs")
  })
  projectile.die()
end