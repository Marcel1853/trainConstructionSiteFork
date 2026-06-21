---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-------------------------------------------------------------------------------
-- removing trainfuel from the electric trains --------------------------------
-------------------------------------------------------------------------------
require "modding-interface"
local trainfuel = "trainassembly-recipefuel"
local itemOrder = require("prototypes/modded-trains-ordening")
local trainRecipe = require("compat.train_recipe")

-- TCS final compatibility safety wrappers -------------------------------------
local function prototype_exists(type_name, prototype_name)
  return data.raw[type_name] and data.raw[type_name][prototype_name]
end

local function technology_exists(technology_name)
  return data.raw.technology and data.raw.technology[technology_name]
end

local function recipe_exists(recipe_name)
  return data.raw.recipe and data.raw.recipe[recipe_name]
end

local function safe_call(label, fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then log("[TCS compatibility] Skipping " .. label .. ": " .. tostring(err)) end
  return ok
end

local _TCS_recipe_removeIngredient = LSlib.recipe.removeIngredient
LSlib.recipe.removeIngredient = function(recipe_name, ingredient_name)
  if recipe_exists(recipe_name) then
    return safe_call("recipe.removeIngredient " .. tostring(recipe_name), _TCS_recipe_removeIngredient, recipe_name, ingredient_name)
  end
end

local _TCS_recipe_addIngredient = LSlib.recipe.addIngredient
LSlib.recipe.addIngredient = function(recipe_name, ingredient_name, amount)
  if recipe_exists(recipe_name) then
    return safe_call("recipe.addIngredient " .. tostring(recipe_name), _TCS_recipe_addIngredient, recipe_name, ingredient_name, amount)
  end
end

local _TCS_recipe_disable = LSlib.recipe.disable
LSlib.recipe.disable = function(recipe_name)
  if recipe_exists(recipe_name) then
    return safe_call("recipe.disable " .. tostring(recipe_name), _TCS_recipe_disable, recipe_name)
  end
end

local _TCS_technology_addRecipeUnlock = LSlib.technology.addRecipeUnlock
LSlib.technology.addRecipeUnlock = function(technology_name, recipe_name)
  if technology_exists(technology_name) and recipe_exists(recipe_name) then
    return safe_call("technology.addRecipeUnlock " .. tostring(technology_name), _TCS_technology_addRecipeUnlock, technology_name, recipe_name)
  end
end

local _TCS_technology_removePrerequisite = LSlib.technology.removePrerequisite
LSlib.technology.removePrerequisite = function(technology_name, prerequisite_name)
  if technology_exists(technology_name) then
    return safe_call("technology.removePrerequisite " .. tostring(technology_name), _TCS_technology_removePrerequisite, technology_name, prerequisite_name)
  end
end

local _TCS_technology_moveRecipeUnlock = LSlib.technology.moveRecipeUnlock
LSlib.technology.moveRecipeUnlock = function(from_technology, to_technology, recipe_name)
  if technology_exists(from_technology) and technology_exists(to_technology) and recipe_exists(recipe_name) then
    return safe_call("technology.moveRecipeUnlock " .. tostring(recipe_name), _TCS_technology_moveRecipeUnlock, from_technology, to_technology, recipe_name)
  end
end

local _TCS_technology_removeIngredient = LSlib.technology.removeIngredient
LSlib.technology.removeIngredient = function(technology_name, ingredient_name)
  if technology_exists(technology_name) then
    return safe_call("technology.removeIngredient " .. tostring(technology_name), _TCS_technology_removeIngredient, technology_name, ingredient_name)
  end
end

local _TCS_technology_addIngredient = LSlib.technology.addIngredient
LSlib.technology.addIngredient = function(technology_name, amount, ingredient_name)
  if technology_exists(technology_name) then
    return safe_call("technology.addIngredient " .. tostring(technology_name), _TCS_technology_addIngredient, technology_name, amount, ingredient_name)
  end
end

local _TCS_final_item_setSubgroup = LSlib.item.setSubgroup
LSlib.item.setSubgroup = function(type_name, prototype_name, subgroup_name)
  if prototype_exists(type_name, prototype_name) and data.raw["item-subgroup"] and data.raw["item-subgroup"][subgroup_name] then
    return safe_call("item.setSubgroup " .. tostring(type_name) .. "/" .. tostring(prototype_name), _TCS_final_item_setSubgroup, type_name, prototype_name, subgroup_name)
  end
end

local _TCS_final_item_setOrderstring = LSlib.item.setOrderstring
LSlib.item.setOrderstring = function(type_name, prototype_name, order_string)
  if prototype_exists(type_name, prototype_name) then
    return safe_call("item.setOrderstring " .. tostring(type_name) .. "/" .. tostring(prototype_name), _TCS_final_item_setOrderstring, type_name, prototype_name, order_string)
  end
end

if mods["Realistic_Electric_Trains"] then
  trainConstructionSite.remote.addElectricTrain("locomotive", "ret-electric-locomotive"    )
  trainConstructionSite.remote.addElectricTrain("locomotive", "ret-electric-locomotive-mk2")
  trainConstructionSite.remote.addElectricTrain("locomotive", "ret-modular-locomotive"     )
end

if mods["Electronic_Locomotives"] then
  trainConstructionSite.remote.addElectricTrain("locomotive", "Electronic-Standard-Locomotive")
  trainConstructionSite.remote.addElectricTrain("locomotive", "Electronic-Cargo-Locomotive"   )
end

if mods["Electronic_Factorio_Extended_Locomotives"] then
  trainConstructionSite.remote.addElectricTrain("locomotive", "electronic-locomotive-mk2")
  trainConstructionSite.remote.addElectricTrain("locomotive", "electronic-locomotive-mk3")
end

if mods["Electronic_Angels_Locomotives"] then
  if mods["angelsaddons-crawlertrain"] or (mods["angelsaddons-mobility"] and angelsmods and angelsmods.addons and angelsmods.addons.mobility and angelsmods.addons.mobility.crawlertrain and angelsmods.addons.mobility.crawlertrain.enabled) then
    local loconame = "electronic-crawler-locomotive"
    local locowagonname = "electronic-crawler-locomotive-wagon"

    local tier_amount = (mods["angelsaddons-crawlertrain"] and angelsmods and angelsmods.addons and angelsmods.addons.crawlertrain and angelsmods.addons.crawlertrain.tier_amount) or
                        (mods["angelsaddons-mobility"] and angelsmods and angelsmods.addons and angelsmods.addons.mobility and angelsmods.addons.mobility.crawlertrain and angelsmods.addons.mobility.crawlertrain.tier_amount)
    for i = 1, (tier_amount or 0) do
      if i == 1 then
        trainConstructionSite.remote.addElectricTrain("locomotive", loconame)
        trainConstructionSite.remote.addElectricTrain("locomotive", locowagonname)
      else
        trainConstructionSite.remote.addElectricTrain("locomotive", loconame.."-"..i)
        trainConstructionSite.remote.addElectricTrain("locomotive", locowagonname.."-"..i)
      end
    end
  end

  if mods["angelsaddons-petrotrain"] or (mods["angelsaddons-mobility"] and angelsmods and angelsmods.addons and angelsmods.addons.mobility and angelsmods.addons.mobility.petrotrain and angelsmods.addons.mobility.petrotrain.enabled) then
    local loconame = "electronic-petro-locomotive-1"

    local tier_amount = (mods["angelsaddons-petrotrain"] and angelsmods and angelsmods.addons and angelsmods.addons.petrotrain and angelsmods.addons.petrotrain.tier_amount) or
                        (mods["angelsaddons-mobility"] and angelsmods and angelsmods.addons and angelsmods.addons.mobility and angelsmods.addons.mobility.petrotrain and angelsmods.addons.mobility.petrotrain.tier_amount)
    for i = 1, (tier_amount or 0) do
      if i == 1 then
        trainConstructionSite.remote.addElectricTrain("locomotive", loconame)
      else
        trainConstructionSite.remote.addElectricTrain("locomotive", loconame.."-"..i)
      end
    end
  end

  if mods["angelsaddons-smeltingtrain"] or (mods["angelsaddons-mobility"] and angelsmods and angelsmods.addons and angelsmods.addons.mobility and angelsmods.addons.mobility.smeltingtrain and angelsmods.addons.mobility.smeltingtrain.enabled) then
    local loconame = "electronic-smelting-locomotive-1"
    local locowagonname = "electronic-smelting-locomotive-tender"

    local tier_amount = (mods["angelsaddons-smeltingtrain"] and angelsmods and angelsmods.addons and angelsmods.addons.smeltingtrain and angelsmods.addons.smeltingtrain.tier_amount) or
                        (mods["angelsaddons-mobility"] and angelsmods and angelsmods.addons and angelsmods.addons.mobility and angelsmods.addons.mobility.smeltingtrain and angelsmods.addons.mobility.smeltingtrain.tier_amount)
    for i = 1, (tier_amount or 0) do
      if i == 1 then
        trainConstructionSite.remote.addElectricTrain("locomotive", loconame)
        trainConstructionSite.remote.addElectricTrain("locomotive", locowagonname)
      else
        trainConstructionSite.remote.addElectricTrain("locomotive", loconame.."-"..i)
        trainConstructionSite.remote.addElectricTrain("locomotive", locowagonname.."-"..i)
      end
    end
  end
end

if mods["Electronic_Battle_Locomotives"] then
  trainConstructionSite.remote.addElectricTrain("locomotive", "Electronic-Battle-Locomotive-1")
  trainConstructionSite.remote.addElectricTrain("locomotive", "Electronic-Battle-Locomotive-2")
  trainConstructionSite.remote.addElectricTrain("locomotive", "Electronic-Battle-Locomotive-3")
end

if mods["ElectricTrain"] then
  trainConstructionSite.remote.addElectricTrain("locomotive", "et-electric-locomotive-1")
  trainConstructionSite.remote.addElectricTrain("locomotive", "et-electric-locomotive-2")
  trainConstructionSite.remote.addElectricTrain("locomotive", "et-electric-locomotive-3")
end

if mods["pyhightech"] then
  trainConstructionSite.remote.addCustomFuelTrain("locomotive", "ht-locomotive", "nexelit-battery")
end

if mods["EditorExtensions"] then
  trainConstructionSite.remote.addElectricTrain("locomotive", "ee-super-locomotive")
end

for trainType,trainData in pairs(trainConstructionSite.remoteData.electricTrains or {}) do
  for trainName,_ in pairs(trainData or {}) do
    LSlib.recipe.removeIngredient(trainRecipe.make_name(trainName, trainType), trainfuel)
  end
end

for trainType,trainData in pairs(trainConstructionSite.remoteData.customFuelTrains or {}) do
  for trainName,customFuelName in pairs(trainData or {}) do
    LSlib.recipe.removeIngredient(trainRecipe.make_name(trainName, trainType), trainfuel)
    LSlib.recipe.addIngredient(trainRecipe.make_name(trainName, trainType), customFuelName)
  end
end

-------------------------------------------------------------------------------
-- Other changes --------------------------------------------------------------
-------------------------------------------------------------------------------
local trainOrdering = require("prototypes.modded-trains-ordening")
local collision_mask_util = require("collision-mask-util")

if mods["FARL"] then
    if data.raw.technology["rail-signals"] then
      LSlib.technology.removePrerequisite("rail-signals", "trainassembly-automated-train-assembling")
      LSlib.technology.moveRecipeUnlock("rail-signals", "trainassembly-automated-train-assembling", "farl")
    end
    LSlib.technology.addRecipeUnlock("trainassembly-automated-train-assembling", trainRecipe.make_name("farl", "locomotive"))
end

if mods["TrainOverhaul"] then
  LSlib.technology.addRecipeUnlock("nuclear-locomotive", trainRecipe.make_name("nuclear-locomotive", "locomotive"))
end

if mods["MultipleUnitTrainControl"] then
  for locomotive,_ in pairs(data.raw["locomotive"]) do
    if string.sub(locomotive, -3) == "-mu" then
      local recipe = data.raw["recipe"][locomotive]
      if recipe then recipe.allow_as_intermediate = false end

      local item = data.raw["item"][locomotive] or data.raw["item-with-entity-data"][locomotive]
      if item then LSlib.item.setHidden(item.type, locomotive) end
    end
  end
end

if mods["angelsindustries"] then
  -- industries overhaul changes the location of the base game subgroup
  if data.raw["item-subgroup"] and data.raw["item-subgroup"]["transport"] then
    data.raw["item-subgroup"]["transport"].group = "transport-logistics"
    data.raw["item-subgroup"]["transport"].order = "d"
  end

  -- industries overhaul changes the order and subgroup of the vanilla trains
  for _, trainData in pairs{
    {"locomotive", "locomotive"},
    {"cargo-wagon", "cargo-wagon"},
    {"fluid-wagon", "fluid-wagon"},
    {"artillery-wagon", "artillery-wagon"},
  } do
    local item = prototype_exists("item-with-entity-data", trainData[2])
    if item and trainOrdering[trainData[1]] and trainOrdering[trainData[1]][trainData[2]] then
      item.order = trainOrdering[trainData[1]][trainData[2]]
      item.subgroup = "transport"
    end
  end

  if settings.startup["angels-enable-tech"] and settings.startup["angels-enable-tech"].value then
    LSlib.technology.removeIngredient("trainfuel-wood-pellets", "datacore-processing-1")
    LSlib.technology.removeIngredient("trainfuel-coal-crushed", "datacore-processing-1")
    LSlib.technology.removeIngredient("trainfuel-solid-coke", "datacore-processing-1")
    LSlib.technology.removeIngredient("trainfuel-solid-carbon", "datacore-processing-1")
    LSlib.technology.removeIngredient("trainfuel-wood-charcoal", "datacore-processing-1")
    LSlib.technology.removeIngredient("trainfuel-rocket-booster", "datacore-processing-1")
    LSlib.technology.removeIngredient("trainfuel-wood-bricks", "datacore-processing-1")
    LSlib.technology.removeIngredient("trainfuel-pellet-coke", "datacore-processing-1")
    LSlib.technology.addIngredient("trainfuel-rocket-booster", 1, "datacore-logistic-1")
  end
end

if mods["Krastorio2"] then
  -- nuclear locomotive technology is not available in data update stage, custom fixing it here
  LSlib.technology.addRecipeUnlock("kr-nuclear-locomotive", trainRecipe.make_name("kr-nuclear-locomotive", "locomotive"))
  LSlib.recipe.disable(trainRecipe.make_name("kr-nuclear-locomotive", "locomotive"))
end

if mods["space-exploration"] then
  -- space exploration moves the base game locomotives around... fixing it here
  for _, trainData in pairs{
    {"locomotive", "locomotive"},
    {"cargo-wagon", "cargo-wagon"},
    {"fluid-wagon", "fluid-wagon"},
    {"artillery-wagon", "artillery-wagon"}
  } do
    if itemOrder[trainData[1] or ""] and itemOrder[trainData[1] or ""][trainData[2] or ""] then
      LSlib.item.setSubgroup("item-with-entity-data", trainData[2] or "", "transport")
      LSlib.item.setOrderstring("item-with-entity-data", trainData[2] or "", itemOrder[trainData[1] or ""][trainData[2] or ""])
    end
  end

  -- space exploration moves rail stuff around... fixing it here
  LSlib.item.setSubgroup("rail-planner", "rail", "transport-railway")
  LSlib.item.setOrderstring("rail-planner", "rail", "a[rail]-a[stone]")
  LSlib.item.setSubgroup("rail-planner", "se-space-rail", "transport-railway")
  LSlib.item.setOrderstring("rail-planner", "se-space-rail", "a[rail]-b[space]")

  LSlib.item.setSubgroup("item", "train-stop", "transport-railway")
  LSlib.item.setOrderstring("item", "train-stop", "b[stop]-a[regular]")

  LSlib.item.setSubgroup("item", "rail-signal", "transport-railway")
  LSlib.item.setOrderstring("item", "rail-signal", "c[signal]-a[rail]")
  LSlib.item.setSubgroup("item", "rail-chain-signal", "transport-railway")
  LSlib.item.setOrderstring("item", "rail-chain-signal", "c[signal]-b[chain]")
end

-- Cargo ships change the order to fit in Transport Logistics instead of Logistics
if mods ["cargo-ships"] then
  local subgroup = data.raw["item-subgroup"]["water_transport"]
  if subgroup then
    subgroup.group = "transport-logistics"
    subgroup.order = "i[water]"
  end
end

-- Hovercraft add train-layer to the construction sites
if mods ["Hovercrafts"] then
  data.raw["assembling-machine"]["trainassembly-machine"].collision_mask.layers["train"] = nil
end
