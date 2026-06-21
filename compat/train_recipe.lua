---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
local train_recipe = {}

train_recipe.train_types = {
  "locomotive",
  "cargo-wagon",
  "fluid-wagon",
  "artillery-wagon",
}

function train_recipe.make_name(train_entity_name, train_type)
  return train_entity_name .. "-fluid-" .. train_type
end

function train_recipe.parse_name(recipe_name)
  if not recipe_name then return nil, nil end
  for _, train_type in pairs(train_recipe.train_types) do
    local suffix = "-fluid-" .. train_type
    if string.sub(recipe_name, -#suffix) == suffix then
      return string.sub(recipe_name, 1, #recipe_name - #suffix), train_type
    end
  end
  return nil, nil
end

return train_recipe
