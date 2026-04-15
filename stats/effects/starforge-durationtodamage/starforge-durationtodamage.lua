function init()
  self.durationDamageMultiplier = effect.duration() * 0.001
  
  --For shotguns/multi hits
  local damageNotifications, nextStep = status.damageTakenSince(self.queryDamageSince)
  self.queryDamageSince = nextStep
end

function update()
  local damageNotifications, nextStep = status.damageTakenSince(self.queryDamageSince)
  self.queryDamageSince = nextStep
  local totalDamage = 0
  for x, notification in ipairs(damageNotifications) do
    totalDamage = totalDamage + math.ceil(notification.damageDealt)
  end
  processHit(totalDamage * self.durationDamageMultiplier)
  effect.expire()
end

function processHit(damage)
  status.applySelfDamageRequest({
    damageType = "IgnoresDef",
    damage = damage,
    damageSourceKind = config.getParameter("damageSourceKind", "default"),
    sourceEntityId = effect.sourceEntity()
  })
end