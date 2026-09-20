---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Technologien an bereits freigeschaltete Rezepte anpassen.
-- Teil von on_configuration_changed, siehe init.lua.

return function()
  --------------------------------------------------
  -- Prototype data                               --
  --------------------------------------------------
  for forceName, force in pairs(game.forces) do
    local technologies = force.technologies
    local recipes      = force.recipes

    if recipes["locomotive"].enabled then
      technologies["trainassembly-automated-train-assembling"].researched = true
    end

    if recipes["cargo-wagon"].enabled then
      technologies["trainassembly-cargo-wagon"].researched = true
   end

    if recipes["artillery-wagon"].enabled then
      technologies["trainassembly-artillery-wagon"].researched = true
    end

    force.reset_technology_effects()
  end

end
