---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
local collision_mask_util = require "collision-mask-util"

-- collision masks
local extraLayer1 = "trainconstruction-site-rail-layer" -- for non-straight rails/signals
local extraLayer2 = "transport_belt" -- for belts (base collision layer name in Factorio 2.0)

data:extend{{type = "collision-layer", name = extraLayer1}}

local function add_layer(mask, layer)
  mask.layers = mask.layers or {}
  mask.layers[layer] = true
end

-- add collision mask to the trainassembler itself
for _,extraLayer in pairs{extraLayer1, extraLayer2} do
  add_layer(data.raw["assembling-machine"]["trainassembly-placeable"].collision_mask, extraLayer)
  if mods["trainDeconstructionSite"] and data.raw["locomotive"]["traindisassembly-placeable"] then
    add_layer(data.raw["locomotive"]["traindisassembly-placeable"].collision_mask, extraLayer)
  end
end

-- add collision mask to rails. Factorio 2.0 split curved rails into multiple rail prototypes.
for _, railType in pairs{
  "curved-rail",
  "legacy-curved-rail",
  "curved-rail-a",
  "curved-rail-b",
  "half-diagonal-rail",
  "rail-ramp",
  "elevated-straight-rail",
  "elevated-curved-rail-a",
  "elevated-curved-rail-b",
  "elevated-half-diagonal-rail",
} do
  for _, railData in pairs(data.raw[railType] or {}) do
    railData.collision_mask = util.table.deepcopy(collision_mask_util.get_mask(railData))
    add_layer(railData.collision_mask, extraLayer1)
    railData.selection_priority = 49 -- default is 50
  end
end

-- add collision mask to signals
for _, signalType in pairs({"rail-signal", "rail-chain-signal"}) do
  for _, signalData in pairs(data.raw[signalType] or {}) do
    signalData.collision_mask = util.table.deepcopy(collision_mask_util.get_mask(signalData))
    add_layer(signalData.collision_mask, extraLayer1)
  end
end

-- add collision mask to belts
for _, beltType in pairs({
  "transport-belt",
}) do
  for _, beltEntity in pairs(data.raw[beltType] or {}) do
    beltEntity.collision_mask = util.table.deepcopy(collision_mask_util.get_mask(beltEntity))
    add_layer(beltEntity.collision_mask, extraLayer2)
  end
end
for _, beltType in pairs({
  "underground-belt",
  "splitter",
}) do
  for _, beltEntity in pairs(data.raw[beltType] or {}) do
    beltEntity.collision_mask = util.table.deepcopy(collision_mask_util.get_mask(beltEntity))
    add_layer(beltEntity.collision_mask, extraLayer2)
  end
end
