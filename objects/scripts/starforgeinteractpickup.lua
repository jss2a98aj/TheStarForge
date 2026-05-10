function init()
  if not storage.itemHasSpawned then
    object.setInteractive(true)
    animator.setAnimationState("objectState", "filled")
    storage.itemHasSpawned = false
  else
    animator.setAnimationState("objectState", "empty")
	  object.setInteractive(false)
  end
  
  self.spawnableItem = config.getParameter("spawnableItem")
  self.useFloatingObject = config.getParameter("useFloatingObject", false)
  self.floatingObjectCycle = config.getParameter("floatingObjectCycle", 1.0) / (2 * math.pi)
  self.floatingObjectMaxTransform = config.getParameter("floatingObjectMaxTransform", 1.0)
  self.timer = 0

  self.messageConfig = config.getParameter("messageConfig")
  if self.messageConfig then
    message.setHandler(self.messageConfig.receiveMessage, function(_, _)
      storage.messageReceived = true
    end)
  end
  
  --Optionally reset the floating object transformation group
  if self.useFloatingObject then
	  animator.resetTransformationGroup("floatingObject")
  end
end

function update(dt)
  --Optionally make the artefact float up and down
  if self.useFloatingObject then
    self.timer = self.timer + dt
    local offset = math.sin(self.timer / self.floatingObjectCycle) * self.floatingObjectMaxTransform
    
    animator.resetTransformationGroup("floatingObject")
    animator.translateTransformationGroup("floatingObject", {0, offset})
  end
end

function open()
  animator.setAnimationState("objectState", "empty")
  local itemToSpawn = {name = self.spawnableItem, parameters = { level = world.threatLevel() }}
  world.spawnItem(itemToSpawn, entity.position(), 1)
  storage.itemHasSpawned = true
  object.setInteractive(false)
  
  --Make sure that, if the object is broken after having been collected, nothing drops
  object.setConfigParameter("breakDropPool", "empty")
end

function onInteraction(args)
  if (self.messageConfig and storage.messageReceived) or not self.messageConfig then
    if storage.itemHasSpawned == false then
      open()
    end
  else
    --Find all nearby entities and send them a set of messages
    local entitiesToMessage = world.entityQuery(entity.position(), self.messageConfig.messageRadius)	
    for _, entity in pairs(entitiesToMessage) do
      world.sendEntityMessage(entity, self.messageConfig.sendMessage)
    end
  end
end