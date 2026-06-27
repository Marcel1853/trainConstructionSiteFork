---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
local itemOverride   = require("prototypes/modded-trains-item-override")
local recipeOverride = require("prototypes/modded-trains-recipe-override")
local trainRecipe    = require("compat.train_recipe")

local function getTrainRecipeLocalisedName(item, trainEntity)
  -- Generated recipe names such as "locomotive-fluid-locomotive" are internal
  -- and intentionally not meant to be shown. Give every generated train-building
  -- recipe the display name of the train it creates, including modded trains.
  if item and item.localised_name then
    return util.table.deepcopy(item.localised_name)
  end
  if trainEntity and trainEntity.localised_name then
    return util.table.deepcopy(trainEntity.localised_name)
  end
  return {"entity-name." .. trainEntity.name}
end

-- For each train-like entity we want to create a recipe so we can put this in
-- our trainbuilding to make an actual train on the tracks. To get the fluidname
-- we require the itemname. To aquire the itemname we get the entity.minable.result.
-- For this we start to iterate over all tine train types
local trainsToIgnore = require("prototypes/modded-trains-to-ignore")
for _, trainType in pairs(trainRecipe.train_types) do
  -- For each type, we get all the different entities (ex: locomotive mk1, mk2, ...)
  for _, trainEntity in pairs(data.raw[trainType] or {}) do
    -- For each entity, we get the item name. The item name is stored in minable.result
    if (not trainsToIgnore[trainType][trainEntity.name]) and trainEntity.minable and trainEntity.minable.result then

      local itemName = itemOverride[trainType][trainEntity.name] or trainEntity.minable.result
      local item = data.raw["item-with-entity-data"][itemName] or data.raw["item"][itemName]
      local fluidRecipeName = trainRecipe.make_name(trainEntity.name, trainType)

      -- now that we have the itemname we can create the fluid recipe.
      data:extend{
        {
          type = "recipe",
          name = fluidRecipeName,
          localised_name = getTrainRecipeLocalisedName(item, trainEntity),
          categories = {"trainassembling"},
          enabled = false,
          energy_required = 15,
          ingredients =
          {
            {type = "item", name = itemName, amount = 1},
          },
          results =
          {
            {
              type    = "fluid",
              name    = itemName .. "-fluid",
              amount  = 1,
            },
          },
          main_product = itemName .. "-fluid",
          always_show_products = true,
        }
      }

      -- Now we created recipes only requiring the item. If this is a locomotive
      -- we will also require fuel to start the engine.
      if trainType == "locomotive" then
        -- This is a locomotive, add another ingredient to the list for fuel
        table.insert(data.raw["recipe"][fluidRecipeName].ingredients, {type = "item", name = "trainassembly-recipefuel", amount = 1})
      end

      -- Now we update the existing recipe. We need to update the localised_name...
      local recipeName = recipeOverride[trainType][trainEntity.name] or itemName
      if item then
        if data.raw.recipe[recipeName] then
          data.raw.recipe[recipeName].icon = nil
          data.raw.recipe[recipeName].icon_size = nil
          data.raw.recipe[recipeName].icon_mipmaps = nil
          data.raw.recipe[recipeName].icons = nil
        end
        FLib.recipe.setLocalisedName(recipeName, util.table.deepcopy(item.localised_name))
        FLib.recipe.setMainResult(recipeName, itemName)
        FLib.recipe.setShowProduct(recipeName, true)
      end
    end
  end
end


if data.raw["item-with-entity-data"]["locomotive-manual-build"] then
  data:extend{{
    type = "recipe",
    name = "locomotive-manual-build",
    localised_name = {"entity-name.locomotive"},
    categories = {"manual-crafting"},
    enabled = false,
    energy_required = 5,
    always_show_made_in = true,
    ingredients =
    {
      {type = "item", name = "locomotive", amount = 1},
    },
    results = {{type = "item", name = "locomotive-manual-build", amount = 1}},
  }}
end
