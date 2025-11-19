function init()
  local elementalResistance = config.getParameter("elementalType", "tidalfrost") .. "Resistance"

  if not status.stat(elementalResistance) then
    local elementalInfluences = config.getParameter("elementalInfluences", {})
    local totalFactor = config.getParameter("totalFactor", 0.5)

    local resistance = 0
    local averageFactor = 0
    local totalRes = 0
    for element, influence in pairs(elementalInfluences) do
      local elementRes = status.stat(element .. "Resistance")
      averageFactor = averageFactor + 1
      totalRes = totalRes + elementRes
      resistance = resistance + elementRes * influence
    end
    local newInfluence = (totalRes / averageFactor) * totalFactor
    
    local finalResistance = resistance + newInfluence
    effect.addStatModifierGroup({{stat = elementalResistance, amount = finalResistance}})
  end

  script.setUpdateDelta(0)
end