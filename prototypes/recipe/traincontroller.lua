---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
data:extend{
  {
    type = "recipe",
    name = "traincontroller",
    enabled = false,
    energy_required = 1,
    ingredients =
    {
      {type = "item", name = "rail-signal", amount = 1},
      {type = "item", name = "decider-combinator", amount = 3},
      {type = "item", name = "arithmetic-combinator", amount = 1},
      {type = "item", name = "programmable-speaker", amount = 2},
    },
    results =
    {
      {
        type    = "item",
        name    = "traincontroller",
        amount  = 1,
      },
    },
  }
}
