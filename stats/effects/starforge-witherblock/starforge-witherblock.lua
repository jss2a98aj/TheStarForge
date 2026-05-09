function init()
  self.modifierId = effect.addStatModifierGroup({{stat = "starforge-witherWeatherStatusImmunity", amount = 1}})
end

function uninit()
  effect.removeStatModifierGroup(self.modifierId)
end