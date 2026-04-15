local baseInit = init or function() end
function init() baseInit()
  self.fullPower = projectile.power()
  self.armourPiercingFactor = config.getParameter("armourPiercingFactor", 0.5)
  projectile.setPower(self.fullPower * self.armourPiercingFactor)
  self.effect = config.getParameter("effectOverwrite", "starforge-armourpiercing")
end

local baseHit = hit or function() end
function hit(entityId) baseHit(entityId)
  world.sendEntityMessage(entityId, "applyStatusEffect", self.effect, self.armourPiercingFactor * 1000, projectile.sourceEntity() or entity.id())
end

