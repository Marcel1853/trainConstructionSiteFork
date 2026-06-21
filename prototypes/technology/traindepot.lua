---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

table.insert(data.raw["technology"]["automated-rail-transportation"].effects,
{
  type = "unlock-recipe",
  recipe = "traindepot",
})


table.insert(data.raw["technology"]["automated-rail-transportation"].prerequisites, "circuit-network")
