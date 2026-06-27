---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- TCS compatibility safety wrappers -------------------------------------------------
-- Many entries in this file target old optional mods. Factorio 2.0 forks may rename
-- or remove prototypes. These wrappers make missing optional prototypes a skip instead
-- of a data-stage crash.
local function prototype_exists(type_name, prototype_name)
  return data.raw[type_name] and data.raw[type_name][prototype_name]
end

local function subgroup_exists(subgroup_name)
  return data.raw["item-subgroup"] and data.raw["item-subgroup"][subgroup_name]
end

local _TCS_LSlib_item_setSubgroup = FLib.item.setSubgroup
FLib.item.setSubgroup = function(type_name, prototype_name, subgroup_name)
  if prototype_exists(type_name, prototype_name) and subgroup_exists(subgroup_name) then
    local ok, err = pcall(_TCS_LSlib_item_setSubgroup, type_name, prototype_name, subgroup_name)
    if not ok then log("[TCS compatibility] Skipping item subgroup update for " .. tostring(type_name) .. "/" .. tostring(prototype_name) .. ": " .. tostring(err)) end
  end
end

local _TCS_LSlib_item_setOrderstring = FLib.item.setOrderstring
FLib.item.setOrderstring = function(type_name, prototype_name, order_string)
  if prototype_exists(type_name, prototype_name) then
    local ok, err = pcall(_TCS_LSlib_item_setOrderstring, type_name, prototype_name, order_string)
    if not ok then log("[TCS compatibility] Skipping item order update for " .. tostring(type_name) .. "/" .. tostring(prototype_name) .. ": " .. tostring(err)) end
  end
end

-- Other mod items related to trains to be sorted
require "prototypes/modded-updates-trainfuel"
local otherVehicleGroup = "manual-buildable-vehicles"

if mods["concreted-rails"] then
  FLib.item.setSubgroup("rail-planner", "concrete-rail", FLib.item.getSubgroup("rail-planner", "rail"))
  FLib.item.setOrderstring("rail-planner", "concrete-rail", "a[rail]-b[concreted-rails]")
end

if mods["FuelTrainStop"] then
  FLib.item.setSubgroup("item", "fuel-train-stop", FLib.item.getSubgroup("item", "train-stop"))
  FLib.item.setOrderstring("item", "fuel-train-stop", "b[stop]-c[FuelTrainStop]")
end

if mods["Armored-train"] then
  for _,itemName in pairs{ -- turret ingredients
    --"platform-minigun-turret-mk1",
    --"wagon-cannon-turret-mk1"    ,
    --"platform-rocket-turret-mk1" ,
  } do
    FLib.item.setSubgroup("item", itemName, FLib.item.getSubgroup("item", "gun-turret"))
    FLib.item.setOrderstring("item", itemName, "b[turret]-a[gun-turret]-h[Armored-train]-"..(FLib.item.getSubgroup("item", itemName) or "z[unknownSubgroup]"))
  end
end

if mods["FARL"] then
  FLib.item.setSubgroup("item", "farl-roboport", otherVehicleGroup)
  FLib.item.setOrderstring("item", "farl-roboport", "a[railway]-b[FARL]")
end

if mods["SmartTrains"] then
  FLib.item.setSubgroup("item", "smart-train-stop", FLib.item.getSubgroup("item", "train-stop"))
  FLib.item.setOrderstring("item", "smart-train-stop", "b[stop]-d[SmartTrains]")
end

if mods["RailPowerSystem"] then
  FLib.item.setSubgroup("rail-planner", "electric-rail", FLib.item.getSubgroup("rail-planner", "rail"))
  FLib.item.setSubgroup("item", "prototype-connector"  , FLib.item.getSubgroup("rail-planner", "rail"))
  FLib.item.setOrderstring("rail-planner", "electric-rail", "a[rail]-c[RailPowerSystem]-a[rail]")
  FLib.item.setOrderstring("item", "prototype-connector"  , "a[rail]-c[RailPowerSystem]-b[pole]")
end

if mods["assembler-pipe-passthrough"] then
  if appmod and appmod.blacklist then
    appmod.blacklist["trainassembly-machine"] = true
  end
end

if mods["boblogistics"] then
  if settings.startup["bobmods-logistics-inserteroverhaul"].value == true then
    -- recipe utilizing express inserters -> move over to fast inserter instead
    FLib.recipe.editIngredient("trainassembly", "fast-inserter", "long-handed-inserter")
  end
end

if mods["bobwarfare"] and (not mods["angelsindustries"]) then
  FLib.item.setSubgroup("item-with-entity-data", "bob-tank-2", otherVehicleGroup)
  FLib.item.setSubgroup("item-with-entity-data", "bob-tank-3", otherVehicleGroup)
end

if mods["FactorioExtended-Plus-Transport"] then
  FLib.item.setSubgroup("item-with-entity-data", "car-mk2", otherVehicleGroup)
  FLib.item.setSubgroup("item-with-entity-data", "car-mk3", otherVehicleGroup)
  FLib.item.setSubgroup("item-with-entity-data", "tank-mk2", otherVehicleGroup)
  FLib.item.setSubgroup("item-with-entity-data", "tank-mk3", otherVehicleGroup)
  FLib.item.setOrderstring("item-with-entity-data", "car", "b-aa")
  FLib.item.setOrderstring("item-with-entity-data", "car-mk2", "b-ab")
  FLib.item.setOrderstring("item-with-entity-data", "car-mk3", "b-ac")
  FLib.item.setOrderstring("item-with-entity-data", "tank", "b-ba")
  FLib.item.setOrderstring("item-with-entity-data", "tank-mk2", "b-bb")
  FLib.item.setOrderstring("item-with-entity-data", "tank-mk3", "b-bc")
end

if mods["Krastorio2"] then
  FLib.item.setSubgroup("item-with-entity-data", "kr-advanced-tank", otherVehicleGroup)
  FLib.item.setOrderstring("item-with-entity-data", "kr-advanced-tank", "c")
end

if mods["LogisticTrainNetwork"] then
  FLib.item.setSubgroup("item", "logistic-train-stop", "transport-railway")
  FLib.item.setOrderstring("item", "logistic-train-stop", "b[stop]-c[LTN]")
end

if mods["Hovercrafts"] then
  local hovercraftVehicleGroup = "hovercrafts"
  FLib.item.setSubgroup("item-with-entity-data", "hcraft-item", hovercraftVehicleGroup)
  FLib.item.setSubgroup("item-with-entity-data", "hcraft-entity", hovercraftVehicleGroup)
  FLib.item.setOrderstring("item-with-entity-data", "hcraft-item", "y[hover]-a[regular]")
  FLib.item.setOrderstring("item-with-entity-data", "hcraft-entity", "y[hover]-a[regular]")

  FLib.item.setSubgroup("item-with-entity-data", "mcraft-item", hovercraftVehicleGroup)
  FLib.item.setSubgroup("item-with-entity-data", "mcraft-entity", hovercraftVehicleGroup)
  FLib.item.setOrderstring("item-with-entity-data", "mcraft-item", "y[hover]-b[missile]")
  FLib.item.setOrderstring("item-with-entity-data", "mcraft-entity", "y[hover]-b[missile]")

  if data.raw["item-with-entity-data"]["ecraft-entity"] then
    FLib.item.setSubgroup("item-with-entity-data", "ecraft-item", hovercraftVehicleGroup)
    FLib.item.setSubgroup("item-with-entity-data", "ecraft-entity", hovercraftVehicleGroup)
    FLib.item.setOrderstring("item-with-entity-data", "ecraft-item", "y[hover]-c[electric]")
    FLib.item.setOrderstring("item-with-entity-data", "ecraft-entity", "y[hover]-c[electric]")
  end

  if data.raw["item-with-entity-data"]["lcraft-entity"] then
    FLib.item.setSubgroup("item-with-entity-data", "lcraft-item", hovercraftVehicleGroup)
    FLib.item.setSubgroup("item-with-entity-data", "lcraft-entity", hovercraftVehicleGroup)
    FLib.item.setOrderstring("item-with-entity-data", "lcraft-item", "y[hover]-d[laser]")
    FLib.item.setOrderstring("item-with-entity-data", "lcraft-entity", "y[hover]-d[laser]")
  end
end

if mods["laser_tanks"] then
  FLib.item.setSubgroup("item-with-entity-data", "lasercar", otherVehicleGroup)
  FLib.item.setOrderstring("item-with-entity-data", "car", "b-aa")
  FLib.item.setOrderstring("item-with-entity-data", "lasercar", "b-ad")

  FLib.item.setSubgroup("item-with-entity-data", "lasertank", otherVehicleGroup)
  FLib.item.setOrderstring("item-with-entity-data", "tank", "b-ba")
  FLib.item.setOrderstring("item-with-entity-data", "lasertank", "b-bd")
end

if mods["Transport_Drones"] and subgroup_exists("transport-drones") then
  data.raw["item-subgroup"]["transport-drones"].group = "transport-logistics"
  data.raw["item-subgroup"]["transport-drones"].order = "aa"
end

if mods["aai-programmable-vehicles"] then
  if subgroup_exists("programmable-structures") then
    data.raw["item-subgroup"]["programmable-structures"].group = "transport-logistics"
    data.raw["item-subgroup"]["programmable-structures"].order = "ab"
  end
  if subgroup_exists("ai-vehicles") then
    data.raw["item-subgroup"]["ai-vehicles"].group = "transport-logistics"
    data.raw["item-subgroup"]["ai-vehicles"].order = "cc-a"
  end
  if subgroup_exists("ai-vehicles-reverse") then
    data.raw["item-subgroup"]["ai-vehicles-reverse"].group = "transport-logistics"
    data.raw["item-subgroup"]["ai-vehicles-reverse"].order = "cc-b"
  end
end

if mods["Cannon_Spidertron"] then
  FLib.item.setSubgroup("item-with-entity-data", "cannon-spidertron", otherVehicleGroup)
  FLib.item.setOrderstring("item-with-entity-data", "cannon-spidertron", string.format("b-%s",
    FLib.item.getOrderstring("item-with-entity-data", "cannon-spidertron") or "z[error]"))
end

if mods["JunkTrain3"] and data.raw["item-subgroup"] and data.raw["item-subgroup"]["transport"] then
  local transportRailway = util.table.deepcopy(data.raw["item-subgroup"]["transport"])
  transportRailway.name = "TCS-JunkTrain"
  transportRailway.group = "transport-logistics"
  transportRailway.order = "a-b[JunkTrain]"
  data:extend({transportRailway})

  FLib.item.setSubgroup("rail-planner", "scrap-rail", transportRailway.name)
  FLib.item.setOrderstring("rail-planner", "scrap-rail",
    FLib.item.getOrderstring("rail-planner", "rail") or "z[error]")

  FLib.item.setSubgroup("item", "train-stop-scrap", transportRailway.name)
  FLib.item.setOrderstring("item", "train-stop-scrap",
    FLib.item.getOrderstring("item", "train-stop") or "z[error]")

  FLib.item.setSubgroup("item", "rail-signal-scrap", transportRailway.name)
  FLib.item.setOrderstring("item", "rail-signal-scrap",
    FLib.item.getOrderstring("item", "rail-signal") or "z[error]")

  FLib.item.setSubgroup("item", "rail-chain-signal-scrap", transportRailway.name)
  FLib.item.setOrderstring("item", "rail-chain-signal-scrap",
    FLib.item.getOrderstring("item", "rail-chain-signal") or "z[error]")

  FLib.item.setSubgroup("item", "JunkTrain", transportRailway.name)
  FLib.item.setOrderstring("item", "JunkTrain", "d-a")

  FLib.item.setSubgroup("item", "ScrapTrailer", transportRailway.name)
  FLib.item.setOrderstring("item", "ScrapTrailer", "d-b")
end

if mods["fast_trans"] then
  -- fix localisation from __ENTITY__ to __ITEM__
  for _, itemName in pairs{
    "cargo-wagon-immortal-mk2",
    "cargo-wagon-immortal-mk3",
    "fluid-wagon-immortal-mk2",
    "fluid-wagon-immortal-mk3"
  } do
    local item = data.raw["item-with-entity-data"][itemName]
    if item then
      item.localised_name = {"item-name.trainparts", {"item-name."..itemName}}
      item.localised_description = {"item-description.trainparts", {"", string.format("[img=item/%s] ", itemName.."-trainConstructionSiteDummy"), {"item-name."..itemName}}}
      if data.raw.recipe[itemName] then data.raw.recipe[itemName].localised_name = item.localised_name end
      if data.raw.fluid[itemName.."-fluid"] then data.raw.fluid[itemName.."-fluid"].localised_name = {"item-name."..itemName} end
    end
  end
end