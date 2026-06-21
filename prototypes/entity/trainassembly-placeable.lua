---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Temporary placeable entity for the train assembly item.
--
-- In the 1.1 version this was a locomotive prototype so Factorio handled rail
-- placement preview. Factorio 2.0 changed rolling-stock graphics/placement enough
-- that this caused the builder to look like a normal locomotive while placing.
-- Use a lightweight assembling-machine based preview entity with the original
-- trainassembly graphics instead. Runtime code validates that it is placed on a
-- straight rail and then replaces it with the tracked trainassembly-machine.

local trainassembly = util.table.deepcopy(data.raw["assembling-machine"]["assembling-machine-3"])
trainassembly.name = "trainassembly-placeable"

trainassembly.minable.result = "trainassembly" -- name of the item
trainassembly.placeable_by = {item = trainassembly.minable.result, count = 1}

-- copy localisation from the item
trainassembly.localised_name = util.table.deepcopy(data.raw["item"][trainassembly.minable.result].localised_name)
trainassembly.localised_description = util.table.deepcopy(data.raw["item"][trainassembly.minable.result].localised_description)

-- copy the icon over from the item
trainassembly.icon = util.table.deepcopy(data.raw["item"][trainassembly.minable.result].icon)
trainassembly.icons = util.table.deepcopy(data.raw["item"][trainassembly.minable.result].icons)
trainassembly.icon_size = util.table.deepcopy(data.raw["item"][trainassembly.minable.result].icon_size)
trainassembly.icon_mipmaps = nil

trainassembly.hidden = true
trainassembly.flags = trainassembly.flags or {}
table.insert(trainassembly.flags, "not-blueprintable")

-- selection/collision box
trainassembly.selection_box = {{-3, -3}, {3, 3}}
trainassembly.collision_box = {{-2.95, -3.9}, {2.95, 3.9}}
trainassembly.drawing_box_vertical_extension = 2

-- Do not collide with straight rails/trains. This matches the old 1.1 logic
-- where the train-layer was removed from the locomotive-style collision mask,
-- leaving only player collision. The data-updates step adds custom blockers for
-- curved rails/signals/belts, while runtime code enforces straight-rail placement.
trainassembly.collision_mask = {layers = {player = true}}

trainassembly.fast_replaceable_group = nil
trainassembly.next_upgrade = nil
trainassembly.max_health = data.raw["assembling-machine"]["assembling-machine-2"].max_health
trainassembly.crafting_categories = {"trainassembling"}
trainassembly.crafting_speed = 0.20
trainassembly.energy_usage = "500kW"
trainassembly.module_specification = nil
trainassembly.module_slots = 0
trainassembly.allowed_effects = nil

if trainassembly.energy_source then
  trainassembly.energy_source.render_no_power_icon = false
  trainassembly.energy_source.render_no_network_icon = false
end

local function layer(filename, shift)
  return {
    filename = filename,
    priority = "high",
    width = 512,
    height = 512,
    frame_count = 1,
    line_length = 1,
    scale = 0.5,
    shift = shift,
  }
end

trainassembly.graphics_set = {
  animation = {
    north = {layers = {layer("__trainConstructionSiteFork__/graphics/entity/trainassembly/trainassembly-N.png", util.by_pixel(31.5, -18))}},
    east  = {layers = {layer("__trainConstructionSiteFork__/graphics/entity/trainassembly/trainassembly-E.png", util.by_pixel(30, -28))}},
    south = {layers = {layer("__trainConstructionSiteFork__/graphics/entity/trainassembly/trainassembly-S.png", util.by_pixel(31.5, -18))}},
    west  = {layers = {layer("__trainConstructionSiteFork__/graphics/entity/trainassembly/trainassembly-W.png", util.by_pixel(30, -28))}},
  },
}
trainassembly.animation = nil
trainassembly.working_visualisations = nil

-- no pipe/recipe UI needed on this short-lived preview entity
trainassembly.fluid_boxes = nil
trainassembly.fluid_boxes_off_when_no_fluid_recipe = nil

data:extend{
  trainassembly,
}
