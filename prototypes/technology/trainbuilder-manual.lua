---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

table.insert(data.raw["technology"]["trainassembly-automated-train-assembling"].effects, 1,
{
  type = "unlock-recipe",
  recipe = "trainbuilder-manual",
})
