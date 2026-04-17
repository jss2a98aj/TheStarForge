local oldDetonate = detonate
function detonate()
  if oldDetonate then oldDetonate() end
  projectile.die()
end