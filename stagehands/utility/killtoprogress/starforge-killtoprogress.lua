require "/scripts/stagehandutil.lua"

function init()
  self.open = true

  self.triggerTime = config.getParameter("openDelay")
  self.filterParameter = config.getParameter("filterParameter")
  self.dieOnOpen = config.getParameter("dieOnOpen")
  self.whitelistDamageTeams = config.getParameter("whitelistDamageTeams", {"indiscriminate", "enemy", "passive"})
  self.timer = 0
end

function update()
  local currentEnemies = {}
  for _, id in pairs(broadcastAreaQuery({ includedTypes = {"creature"} })) do
    if world.entityExists(id) and validDamageTeam(id) then
      table.insert(currentEnemies, id)
    end
  end

  if not self.open and #currentEnemies == 0 then
    self.timer = self.timer + script.updateDt()

    if self.timer > self.triggerTime then
      sendMessage("openDoor")
      self.open = true
      self.timer = 0
      if self.dieOnOpen then
        stagehand.die()
      end
    end
  elseif self.open and #currentEnemies ~= 0 then
    sendMessage("lockDoor")
    self.open = false
    self.timer = 0
  end
end

function validDamageTeam(id)
  local valid = false
  for _, team in ipairs(self.whitelistDamageTeams) do
    if world.entityDamageTeam(id).type == team then
      valid = true
    end
  end
  return valid
end

function sendMessage(message)
  local doors = broadcastAreaQuery({ 
    includedTypes = { "object" },
    callScript = "config.getParameter",
    callScriptArgs = { "filterParameter" },
    callScriptResult = self.filterParameter 
  })
  for _, doorId in pairs(doors) do
    world.sendEntityMessage(doorId, message)
  end
end
