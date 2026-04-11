require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

StarforgeAllyMonsterSummon = WeaponAbility:new()

function StarforgeAllyMonsterSummon:init()
  self.cooldownTimer = self.cooldownTime

  self.summonUuids = config.getParameter("summonUuids", {})

  self:reset()
end

function StarforgeAllyMonsterSummon:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  if self.cooldownTimer == 0 then
    for i = 1, #self.summonUuids do
      local summonPos = world.findUniqueEntity(self.summonUuids[i]):result()
      if not summonPos then
        self.summonUuids[i] = nil
      end
    end

    if self.fireMode == "alt"
      and not self.weapon.currentAbility
      and #self.summonUuids == 0
      and not status.resourceLocked("energy") 
      and not world.lineTileCollision(mcontroller.position(), self:summonPosition())
      and status.overConsumeResource("energy", self:energyPerRelease()) then

      self:setState(self.windup)
    end
  end
  world.debugText("%s", self.summonUuids, mcontroller.position(), "red")
end

function StarforgeAllyMonsterSummon:windup()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.windupTime, function(dt)
	  if self.walkWhileFiring == true then
      mcontroller.controlModifiers({runningSuppressed=true})
	  end
  end)
  
  self:setState(self.summon)
end

function StarforgeAllyMonsterSummon:summon()
  self.weapon:setStance(self.stances.summon)
  animator.playSound("summon")

  local damageTeam = entity.damageTeam()
  local monsterSpawnConfigs = sb.jsonMerge(self.monsterConfigs, {})
  for i, monsterConfig in ipairs(self.monsterConfigs) do
    local uuid = sb.makeUuid()
    monsterConfig.uuid = uuid
    self.summonUuids[i] = uuid 

    local baseParams = {
      damageTeam = damageTeam.team,
      damageTeamType = damageTeam.type,
      aggressive = true,
      level = config.getParameter("level") or self.monsterLevel
    }
    monsterConfig.monsterParameters = sb.jsonMerge(monsterConfig.monsterParameters, baseParams)
  end 
  
  self.stagehandId = world.spawnStagehand(self:summonPosition(), "starforge-spawnmonster", {
    monsterConfigs = self.monsterConfigs
  })
 
  self.cooldownTimer = self.cooldownTime
  util.wait(self.stances.summon.duration)
end

function StarforgeAllyMonsterSummon:summonPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.summonOffset))
end

function StarforgeAllyMonsterSummon:energyPerRelease()
  return self.summonEnergyUsage * (self.energyUsageMultiplier or 1.0)
end

function StarforgeAllyMonsterSummon:uninit()
  activeItem.setInstanceValue("summonUuids", self.summonUuids)
  self:reset()
end

function StarforgeAllyMonsterSummon:reset()
end