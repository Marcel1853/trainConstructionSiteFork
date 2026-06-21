---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
local function makeScienceUnit(sourceTechnologyName, count, time)
  local sourceTechnology = data.raw["technology"][sourceTechnologyName] or data.raw["technology"]["railway"]
  local sourceUnit = sourceTechnology and sourceTechnology.unit or data.raw["technology"]["railway"].unit
  return {
    count = count,
    ingredients = util.table.deepcopy(sourceUnit.ingredients),
    time = time,
  }
end

for _, recipeName in pairs{
  "trainassembly-trainfuel-wood",
} do
  table.insert(data.raw["technology"]["trainassembly-automated-train-assembling"].effects,
  {
    type = "unlock-recipe",
    recipe = recipeName,
  })
end



data:extend{ -- add fuel recipe to tech tree
  {
    type = "technology",
    name = "trainfuel-2",
    localised_name = {"technology-name.trainfuel", "trainassemblyfuel", "coal"},
    localised_description = {"technology-description.trainfuel", "trainassemblyfuel", "coal"},
    icons = LSlib.recipe.getIcons("trainassembly-trainfuel-coal"),
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "trainassembly-trainfuel-coal",
      },
    },
    prerequisites =
    {
      "trainassembly-automated-train-assembling",
    },
    unit = makeScienceUnit("railway", 75, 10),
    order = "c-g-a-b",
  },
  {
    type = "technology",
    name = "trainfuel-3",
    localised_name = {"technology-name.trainfuel", "trainassemblyfuel", "solid-fuel"},
    localised_description = {"technology-description.trainfuel", "trainassemblyfuel", "solid-fuel"},
    icons = LSlib.recipe.getIcons("trainassembly-trainfuel-solid-fuel"),
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "trainassembly-trainfuel-solid-fuel",
      },
    },
    prerequisites =
    {
      "trainfuel-2",
      "oil-processing",
    },
    unit = makeScienceUnit("oil-processing", 100, 10),
    order = "c-g-a-c",
  },
  {
    type = "technology",
    name = "trainfuel-4",
    localised_name = {"technology-name.trainfuel", "trainassemblyfuel", "rocket-fuel"},
    localised_description = {"technology-description.trainfuel", "trainassemblyfuel", "rocket-fuel"},
    icons = LSlib.recipe.getIcons("trainassembly-trainfuel-rocket-fuel"),
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "trainassembly-trainfuel-rocket-fuel",
      },
    },
    prerequisites =
    {
      "trainfuel-3",
      "rocket-fuel",
    },
    unit = makeScienceUnit("rocket-fuel", 75, 30),
    order = "c-g-a-d",
  },
  {
    type = "technology",
    name = "trainfuel-5",
    localised_name = {"technology-name.trainfuel", "trainassemblyfuel", "nuclear-fuel"},
    localised_description = {"technology-description.trainfuel", "trainassemblyfuel", "nuclear-fuel"},
    icons = LSlib.recipe.getIcons("trainassembly-trainfuel-nuclear-fuel"),
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "trainassembly-trainfuel-nuclear-fuel",
      },
    },
    prerequisites =
    {
      "trainfuel-4",
      "kovarex-enrichment-process",
    },
    unit = makeScienceUnit("kovarex-enrichment-process", 500, 60),
    order = "c-g-a-e",
  },
}

-- update the icons
for level = 2, 5 do
  for _,iconLayer in pairs(data.raw["technology"][string.format("trainfuel-%i", level)].icons) do
    if iconLayer.icon == "__trainConstructionSiteFork__/graphics/item/trainfuel/loco/loco-64.png" then
      iconLayer.icon      = "__trainConstructionSiteFork__/graphics/item/trainfuel/loco/loco-128.png"
      iconLayer.icon_size = 128
    elseif iconLayer.icon == "__trainConstructionSiteFork__/graphics/item/trainfuel/fuel-handle/fuel-handle-32.png" then
      iconLayer.icon      = "__trainConstructionSiteFork__/graphics/item/trainfuel/fuel-handle/fuel-handle-64.png"
      iconLayer.icon_size = 64
    end
    for shiftAxis,shiftAmount in pairs(iconLayer.shift or {}) do
      iconLayer.shift[shiftAxis] = 2 * shiftAmount
    end
  end
end
