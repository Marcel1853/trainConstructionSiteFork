---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
require("compat.lslib")

local function createRecipeIcons(itemPrototypeName)
  local recipeIcons = util.table.deepcopy(LSlib.item.getIcons("item", "trainassembly-recipefuel"))
  recipeIcons[2].shift = {-16, -20}
  recipeIcons[2].scale = 1.2
  local recipeIconsLength = #recipeIcons -- number of layers to offset the existing layers

  local baseIconSize = recipeIcons[1].icon_size or 64
  local itemIconSize = (LSlib.item.getIconSize("item", itemPrototypeName) or {})[1] or 64
  local extraScale = baseIconSize / itemIconSize
  for layerIndex,layerData in pairs(LSlib.item.getIcons("item", itemPrototypeName, 0.4 * extraScale, {-20, 19})) do
    recipeIcons[recipeIconsLength + layerIndex] = layerData -- add layer to recipelayer
  end
  return recipeIcons
end

if mods["aai-industry"] and type(aai_processed_fuel_ignore) == "table" then
  table.insert(aai_processed_fuel_ignore, "trainassembly-trainfuel")
end

local function technology_unit_or_railway(technologyName)
  local technology = data.raw.technology[technologyName]
  if technology and technology.unit then
    return util.table.deepcopy(technology.unit)
  end
  return util.table.deepcopy(data.raw.technology["railway"].unit)
end

-- We want to create different fuel recipes to create the fuel to initialy fuel the train.
-- We make a fuel for each of the next items:
for fuelOrder, fuelIngredient in pairs{
  mods["aai-industry"       ] and {"processed-fuel", 40, "fuel-processing"} or nil,
  mods["Bio_Industries"     ] and {"pellet-coke" , 10, "bi-tech-coal-processing-2"} or nil,

  mods["angelsbioprocessing"] and {"wood-pellets", 25, "bio-wood-processing"} or nil,
  mods["angelspetrochem"    ] and {"coal-crushed", 100, "angels-coal-processing"} or nil,
  mods["angelspetrochem"    ] and {"solid-coke", 80, "angels-coal-processing"} or nil,
  mods["angelspetrochem"    ] and {"solid-carbon", 45, "angels-coal-processing"} or nil,
  mods["angelsbioprocessing"] and {"wood-charcoal", 35, "bio-wood-processing-2"} or nil,
  mods["angelspetrochem"    ] and {"rocket-booster", 20, "rocket-booster-1"} or nil,
  mods["angelsbioprocessing"] and {"wood-bricks", 10, "bio-wood-processing-3"} or nil,
  mods["angelspetrochem"    ] and {"pellet-coke", 65, "angels-coal-cracking"} or nil,
} do

  if not (fuelIngredient and data.raw.item[fuelIngredient[1]]) then
    log("[TCS compatibility] Skipping train fuel recipe for missing item " .. tostring(fuelIngredient and fuelIngredient[1]))
  else
  -- For this item we create a fuel recipe & technology to unlock it
  data:extend{
    {
      type = "recipe",
      name = "trainassembly-trainfuel-" .. fuelIngredient[1],
      localised_name = {"recipe-name.trainfuel", "trainassemblyfuel", fuelIngredient[1]},
      icons     = createRecipeIcons(fuelIngredient[1]), -- create recipe icons with different layers
      icon      = nil, -- becose icons is present, no icon      required
      icon_size = nil, -- becose icons is present, no icon_size required

      category = "advanced-crafting",
      enabled = false,
      energy_required = 5,
      ingredients =
      {
        {type = "item", name = fuelIngredient[1], amount = ((fuelIngredient[2] > 1) and (fuelIngredient[2]) or 1)},
      },
      results =
      {
        {type = "item", name = "trainassembly-recipefuel", amount = ((fuelIngredient[2] < 1) and (1/fuelIngredient[2]) or 1)},
      },

      -- We have to add a order string to the recipe becose we have multiple
      -- recipes resulting in the same item.
      order = string.format("b-%02d",fuelOrder),
    },
  }
  data:extend{
    {
      type = "technology",
      name = "trainfuel-"..fuelIngredient[1],
      localised_name = {"technology-name.trainfuel", "trainassemblyfuel", fuelIngredient[1]},
      localised_description = {"technology-description.trainfuel", "trainassemblyfuel", fuelIngredient[1]},
      icons = LSlib.recipe.getIcons("trainassembly-trainfuel-"..fuelIngredient[1]),
      effects =
      {
        {
          type = "unlock-recipe",
          recipe = "trainassembly-trainfuel-" .. fuelIngredient[1],
        },
      },
      prerequisites =
      {
        "trainassembly-automated-train-assembling",
      },
      unit = technology_unit_or_railway("railway"),
      order = "c-g-a-b",
    },
  }
  if data.raw.technology[fuelIngredient[3]] then
    LSlib.technology.addPrerequisite("trainfuel-"..fuelIngredient[1], fuelIngredient[3])
    data.raw.technology["trainfuel-"..fuelIngredient[1]].unit = technology_unit_or_railway(fuelIngredient[3])
  end
  end
end
