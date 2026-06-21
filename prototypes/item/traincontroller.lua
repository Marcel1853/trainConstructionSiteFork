---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

local traincontroller = util.table.deepcopy(data.raw["item"]["rail-chain-signal"])

traincontroller.name                  = "traincontroller"
traincontroller.localised_name        = {"item-name.traincontroller", {[1] = "item-name.trainassembly"}}
traincontroller.localised_description = {"item-description.traincontroller", {[1] = "item-name.trainassembly"}}

traincontroller.icon                  = "__trainConstructionSiteFork__/graphics/item/traincontroller/traincontroller.png"
traincontroller.icons                 = nil
traincontroller.icon_size             = 64
traincontroller.icon_mipmaps          = nil

traincontroller.order                 = "d[trainbuilder]-a[construction]-b[controller]"

traincontroller.place_result          = traincontroller.name

traincontroller.stack_size = data.raw["item"]["train-stop"].stack_size



data:extend{
  traincontroller,
}
