---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
data:extend{
  {
    type = "recipe",
    name = "trainassembly",
    category = "advanced-crafting",
    enabled = false,
    energy_required = 30,
    ingredients =
    {
      {type = "item", name = "fast-inserter", amount = 10},
      {type = "item", name = "assembling-machine-2", amount = 2},
      {type = "item", name = "rail", amount = 50},
      {type = "item", name = "electronic-circuit", amount = 10},
    },
    results =
    {
      {
        type    = "item",
        name    = "trainassembly",
        amount  = 1,
      },
    },
  }
}
