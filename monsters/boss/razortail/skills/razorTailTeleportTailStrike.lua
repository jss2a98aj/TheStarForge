razorTailTeleportTailStrike = {}

function razorTailTeleportTailStrike.enter()
  if not hasTarget() then return nil end

  return {
    timer = config.getParameter("razorTailTeleportTailStrike.winddownDuration", 2.5),
    projectileDelay = config.getParameter("razorTailTeleportTailStrike.projectileDelay", 0.5),
    teleportXOffset = config.getParameter("razorTailTeleportTailStrike.teleportXOffset", 7),
    tooCloseRange = config.getParameter("razorTailTeleportTailStrike.tooCloseRange", 4),

    projectileType = config.getParameter("razorTailTeleportTailStrike.projectileType", "standardBullet"),
    projectileConfig = config.getParameter("razorTailTeleportTailStrike.projectileConfig", {}),
    projectileOffset = config.getParameter("razorTailTeleportTailStrike.projectileOffset", {2, 0})
  }
end

function razorTailTeleportTailStrike.enteringState(stateData)
  monster.setActiveSkillName("razorTailTeleportTailStrike")
  razorTailTeleportTailStrike.teleport(stateData)
end

function razorTailTeleportTailStrike.update(dt, stateData) 
  if stateData.timerActive then
    stateData.timer = math.max(0, stateData.timer - dt)
    
    if stateData.timer == 0 then
      return true
    end
  end
  return false
end

function razorTailTeleportTailStrike.teleport(stateData)
  local directionToPlayer = util.toDirection(world.distance(mcontroller.position(), self.targetPosition)[1])
  local teleportPosition = calculatePosition(self.targetPosition, {-directionToPlayer * stateData.teleportXOffset, 0})
  if world.magnitude(teleportPosition, mcontroller.position()) > stateData.tooCloseRange then
    sanctusTeleport(
      teleportPosition,
      0,
      function()
        razorTailTeleportTailStrike.slashProjectile(stateData, directionToPlayer)
      end
    )
  else
    stateData.timer = 0
    stateData.timerActive = true
  end
end

function razorTailTeleportTailStrike.slashProjectile(stateData, directionToPlayer)
  animator.setAnimationState("body", "tailStrike")
  wait(
    stateData.projectileDelay,
    function()
      mcontroller.setVelocity({0, 0})
    end,
    function()
      if animator.hasSound("tailStrike") then
        animator.playSound("tailStrike")
      end
      local projectileConfig = stateData.projectileConfig
      projectileConfig.power = scalePower(stateData.projectileConfig.power or 10)
      world.spawnProjectile(stateData.projectileType, vec2.add(mcontroller.position(), vec2.mul(stateData.projectileOffset, {directionToPlayer, 1})), entity.id(), {directionToPlayer, 0}, false, projectileConfig)
      stateData.timerActive = true
      mcontroller.setVelocity({-directionToPlayer * 15, 10})
      if not self.onGround then
        animator.setAnimationState("body", "falling")
      end
    end)
end

function razorTailTeleportTailStrike.leavingState(stateData)
end
