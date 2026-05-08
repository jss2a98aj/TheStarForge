function init()
  self.messageToSend = config.getParameter("messageToSend")
  self.messageRadius = config.getParameter("messageRadius", 50)
end

function update(dt)
	local targets = world.entityQuery(mcontroller.position(), self.messageRadius, {
	  withoutEntityId = projectile.sourceEntity(),
	  includedTypes = {"creature"},
	  order = "nearest"
  })
  for _, target in pairs(targets) do
	  if world.entityCanDamage(projectile.sourceEntity(), target) then
      world.sendEntityMessage(target, self.messageToSend, 0.025 * world.magnitude(entity.position(), world.entityPosition(target)), projectile.power())
    end
  end
	projectile.die()
end