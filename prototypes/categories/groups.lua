---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

--Maingroup for all the subgroups involved in trains
local transportLogistics = util.table.deepcopy(data.raw["item-group"]["logistics"])
transportLogistics.name = "transport-logistics"
transportLogistics.localised_name = {"item-group-name.transportLogistics"}
transportLogistics.order = transportLogistics.order .. "a[transport]"
transportLogistics.icon = "__trainConstructionSiteFork__/graphics/technology/traincontroller.png"
transportLogistics.icon_size = 128

--Rails, assembler, trainstop, depo, railsignal and chainsignal.
local transportRailway = util.table.deepcopy(data.raw["item-subgroup"]["transport"])
transportRailway.name = "transport-railway"
transportRailway.group = transportLogistics.name
transportRailway.order = "a"

--fuel
local trainassemblerFuel = util.table.deepcopy(transportRailway)
trainassemblerFuel.name = "trainassembler-fuel"
trainassemblerFuel.order = "b"

--manual buildable vehicles
local manualBuildVehicles = util.table.deepcopy(transportRailway)
manualBuildVehicles.name = "manual-buildable-vehicles"
manualBuildVehicles.order = "c"

--trainparts fluid
local trainpartsFluid = util.table.deepcopy(transportRailway)
trainpartsFluid.name = "trainparts-fluid"
trainpartsFluid.order = "e"


data.raw["item-subgroup"]["transport"].group = transportRailway.group
data.raw["item-subgroup"]["transport"].order = "d"


for _, vehicleName in pairs{
  "car",
  "tank",
  "spidertron",
} do

  if data.raw["item-with-entity-data"][vehicleName] then
    data.raw["item-with-entity-data"][vehicleName].subgroup = "manual-buildable-vehicles"
    data.raw["item-with-entity-data"][vehicleName].order = "b-"..data.raw["item-with-entity-data"][vehicleName].order
  end
end

local spidertronRemote = (data.raw["rts-tool"] and data.raw["rts-tool"]["spidertron-remote"]) or
                        (data.raw["spidertron-remote"] and data.raw["spidertron-remote"]["spidertron-remote"])
if spidertronRemote then
  spidertronRemote.subgroup = "manual-buildable-vehicles"
  spidertronRemote.order = "b-"..(spidertronRemote.order or "z")
end





data:extend{
  transportLogistics,
  transportRailway,
  trainassemblerFuel,
  manualBuildVehicles,
  trainpartsFluid,
}
