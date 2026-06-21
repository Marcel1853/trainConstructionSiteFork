---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

local traindepot = util.table.deepcopy(data.raw["train-stop"]["train-stop"])

traindepot.name = "traindepot"

traindepot.minable.result = "traindepot"

traindepot.localised_name = util.table.deepcopy(data.raw["item"][traindepot.minable.result].localised_name)
traindepot.localised_description = util.table.deepcopy(data.raw["item"][traindepot.minable.result].localised_description)

traindepot.icon = util.table.deepcopy(data.raw["item"][traindepot.minable.result].icon)
traindepot.icon_size = util.table.deepcopy(data.raw["item"][traindepot.minable.result].icon_size)
traindepot.icons = util.table.deepcopy(data.raw["item"][traindepot.minable.result].icons)
traindepot.icon_mipmaps = nil

traindepot.rail_overlay_animations = {
  filename = "__core__/graphics/empty.png",
  width = 1,
  height = 1,
  hr_version = nil,
}
traindepot.animations = {
  north =
  {
    filename = "__trainConstructionSiteFork__/graphics/entity/traindepot/traindepot-N-bottom.png",
    priority = "high",
    width = 384,
    height = 384,
    frame_count = 1,
    line_length = 1,
    scale = 0.5,
    shift = util.by_pixel(-8, -20),
    hr_version = nil,
  },
  east =
  {
    filename = "__trainConstructionSiteFork__/graphics/entity/traindepot/traindepot-E-bottom.png",
    priority = "high",
    width = 384,
    height = 384,
    frame_count = 1,
    line_length = 1,
    scale = 0.5,
    shift = util.by_pixel(22, -58),
    hr_version = nil,
  },
  south =
  {
    filename = "__trainConstructionSiteFork__/graphics/entity/traindepot/traindepot-S-bottom.png",
    priority = "high",
    width = 384,
    height = 384,
    frame_count = 1,
    line_length = 1,
    scale = 0.5,
    shift = util.by_pixel(61, 2),
    hr_version = nil,
  },
  west =
  {
    filename = "__trainConstructionSiteFork__/graphics/entity/traindepot/traindepot-W-bottom.png",
    priority = "high",
    width = 384,
    height = 384,
    frame_count = 1,
    line_length = 1,
    scale = 0.5,
    shift = util.by_pixel(18, 4),
    hr_version = nil,
  },
}
traindepot.top_animations = {
  north =
  {
    filename = "__trainConstructionSiteFork__/graphics/entity/traindepot/traindepot-N-top.png",
    priority = "high",
    width = 384,
    height = 384,
    frame_count = 1,
    line_length = 1,
    scale = 0.5,
    shift = util.by_pixel(-8, -20),
    hr_version = nil,
  },
  east =
  {
    filename = "__trainConstructionSiteFork__/graphics/entity/traindepot/traindepot-E-top.png",
    priority = "high",
    width = 384,
    height = 384,
    frame_count = 1,
    line_length = 1,
    scale = 0.5,
    shift = util.by_pixel(22, -58),
    hr_version = nil,
  },
  south =
  {
    filename = "__trainConstructionSiteFork__/graphics/entity/traindepot/traindepot-S-top.png",
    priority = "high",
    width = 384,
    height = 384,
    frame_count = 1,
    line_length = 1,
    scale = 0.5,
    shift = util.by_pixel(61, 2),
    hr_version = nil,
  },
  west =
  {
    filename = "__trainConstructionSiteFork__/graphics/entity/traindepot/traindepot-W-top.png",
    priority = "high",
    width = 384,
    height = 384,
    frame_count = 1,
    line_length = 1,
    scale = 0.5,
    shift = util.by_pixel(18, 4),
    hr_version = nil,
  },
}
traindepot.light1 = {
  light = {intensity = 0, size = 0, color = {r = 1.0, g = 1.0, b = 1.0}},
  picture =
    {
      filename = "__core__/graphics/empty.png",
      width = 1,
      height = 1,
      hr_version = nil,
    },
  red_picture =
    {
      filename = "__core__/graphics/empty.png",
      width = 1,
      height = 1,
      hr_version = nil,
    },
}
traindepot.light2 = {
  light = {intensity = 0, size = 0, color = {r = 1.0, g = 1.0, b = 1.0}},
  picture =
    {
      filename = "__core__/graphics/empty.png",
      width = 1,
      height = 1,
      hr_version = nil,
    },
  red_picture =
    {
      filename = "__core__/graphics/empty.png",
      width = 1,
      height = 1,
      hr_version = nil,
    },
}

traindepot.circuit_wire_max_distance = 0


-- Blueprinting is supported by runtime validation/pending activation in 0.4.1.

data:extend{
  traindepot,
}
