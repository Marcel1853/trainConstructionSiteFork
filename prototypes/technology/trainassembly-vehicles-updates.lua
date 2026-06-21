---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

--Unlocking locomotive manual build in the railway techtree

for _, trainRecipe in pairs ({
  "locomotive-manual-build",
}) do
  if data.raw["recipe"][trainRecipe] then
    table.insert(data.raw["technology"]["railway"].effects,
    {
      type = "unlock-recipe",
      recipe = trainRecipe,
    })
  end
end
