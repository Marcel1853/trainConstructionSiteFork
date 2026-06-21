---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

data.raw["item"]["rail-signal"].subgroup = "transport-railway"
data.raw["item"]["rail-signal"].order ="c[signal]-a[vanilla]-a[rail]"

data.raw["item"]["rail-chain-signal"].subgroup = "transport-railway"
data.raw["item"]["rail-chain-signal"].order = "c[signal]-a[vanilla]-b[chain]"

data.raw["rail-planner"]["rail"].subgroup = "transport-railway"
data.raw["rail-planner"]["rail"].order = "a[rail]-a[vanilla]"

data.raw["item"]["train-stop"].subgroup = "transport-railway"
data.raw["item"]["train-stop"].order = "b[stop]-a[vanilla]"
