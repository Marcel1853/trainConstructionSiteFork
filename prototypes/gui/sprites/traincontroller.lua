---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

for _,direction in pairs{"L", "R"} do
  data:extend{{
    type     = "sprite",
    name     = string.format("traincontroller-orientation-%s", direction),
    filename = string.format("__trainConstructionSiteFork__/graphics/sprite/double_arrow_%s.png", direction),
    width    = 64,
    height   = 64,
    scale    = .5,
    --shift    = {0, 32},
    flags    = {
      "icon",
      "no-crop"
    },
  }}
end
