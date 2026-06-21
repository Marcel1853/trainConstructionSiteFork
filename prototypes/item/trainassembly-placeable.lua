---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

-- the placeable entity is linked to this item
local trainassembly = util.table.deepcopy(data.raw["item"]["rail-chain-signal"])

trainassembly.name                  = "trainassembly"
trainassembly.localised_name        = {"item-name.trainassembly"}
trainassembly.localised_description = {"item-description.trainassembly"}

trainassembly.icon                  = "__trainConstructionSiteFork__/graphics/item/trainassembly/trainassembly.png"
trainassembly.icons                 = nil
trainassembly.icon_size             = 64
trainassembly.icon_mipmaps          = nil

trainassembly.subgroup              = "transport-railway"
trainassembly.order                 = "d[trainbuilder]-a[construction]-a[builder]"

trainassembly.place_result          = "trainassembly-placeable" -- preview entity; script validates rail placement

--trainassembly.stack_size = 10

data:extend{
  trainassembly,
}
