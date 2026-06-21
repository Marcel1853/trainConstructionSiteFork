---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

local traindepot = util.table.deepcopy(data.raw["item"]["train-stop"])

traindepot.name                   = "traindepot"
traindepot.localised_name         = {"item-name.traindepot"}
traindepot.localised_description  = {"item-description.traindepot"}

traindepot.icon                   = "__trainConstructionSiteFork__/graphics/item/traindepot/traindepot.png"
traindepot.icon_size              = 74
traindepot.icons                  = nil
traindepot.icon_mipmaps           = nil

traindepot.order                  = "b[stop]-b[trainbuilding]"

traindepot.place_result           = traindepot.name

data:extend{
  traindepot,
}
