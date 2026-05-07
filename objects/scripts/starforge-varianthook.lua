variantHookInit = init or function() end
function init() variantHookInit()
  storage.variant = storage.variant or math.random(1, config.getParameter("variants", 2))
  storage.flipped = storage.flipped or (config.getParameter("randomFlipping", true) and (math.random() > 0.5 and "?flipx" or "") or "")

  animator.setGlobalTag("variant", storage.variant .. storage.flipped)
end