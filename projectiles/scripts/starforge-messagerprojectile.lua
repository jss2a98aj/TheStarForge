function init()
  self.messageToSend = config.getParameter("messageToSend")
  self.messageArgs = config.getParameter("messageArgs")
  self.messageRadius = config.getParameter("messageRadius", 50)
  self.distanceDetonate = config.getParameter("distanceDetonate")
end

function destroy()
	local targets = world.entityQuery(mcontroller.position(), self.messageRadius, {
	  withoutEntityId = projectile.sourceEntity(),
	  includedTypes = {"creature"},
	  order = "nearest"
  })
  for _, target in pairs(targets) do
	  if world.entityCanDamage(projectile.sourceEntity(), target) then
      if self.distanceDetonate then
        local delay, projectileConfig = table.unpack(self.messageArgs)
        world.sendEntityMessage(target, self.messageToSend, delay * world.magnitude(entity.position(), world.entityPosition(target)), projectile.power(), projectileConfig)
      else
        world.sendEntityMessage(target, self.messageToSend, table.unpack(self.messageArgs))
      end
    end
  end
end