---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
data:extend{
  {
    type = "recipe",
    name = "traindepot",
    enabled = false,
    energy_required = 1,
    ingredients =
    {
      {type = "item", name = "train-stop", amount = 1},
      {type = "item", name = "small-lamp", amount = 3},
      {type = "item", name = "programmable-speaker", amount = 1},
    },
    results =
    {
      {
        type    = "item",
        name    = "traindepot",
        amount  = 1,
      },
    },
  }
}
