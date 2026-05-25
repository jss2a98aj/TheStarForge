starforge_electricalProjectile_init = init
function init(...) if starforge_electricalProjectile_init then starforge_electricalProjectile_init(...) end
  self.parameters = config.getParameter("lightningParameters", {})
  self.parameters.hostProjectile = entity.id()
  self.parameters.hostEntity = projectile.sourceEntity()
  self.parameters.hostVelocity = mcontroller.velocity()
  self.parameters.power = projectile.power()
  --sb.logInfo("POWER IS %s", projectile.power())
  self.parameters.damageTeamType = "friendly"
  self.parameters.level = 1
end

starforge_electricalProjectile_update = update
function update(dt) if starforge_electricalProjectile_update then starforge_electricalProjectile_update(dt) end
  if not self.chainLightningCompanion then
    self.chainLightningCompanion = true
    world.spawnMonster(
      "starforge-projectilelightningchain",
      mcontroller.position(),
      self.parameters
    )
  end
end

starforge_electricalProjectile_detonate = detonate
function detonate(...) if starforge_electricalProjectile_detonate then starforge_electricalProjectile_detonate(...) end
  projectile.die()
end