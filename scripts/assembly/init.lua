---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Trainassembly: die Wagen-Maschinen (trainassembly-machine), aus denen Trainbuilder bestehen.
-- Teile: structure (Speichern/Löschen), quality, getters, builders (Trainbuilder-Verwaltung),
-- placement (Platzieren prüfen), events (Ereignisse).

Trainassembly = {}
require("scripts.assembly.structure")
require("scripts.assembly.quality")
require("scripts.assembly.getters")
require("scripts.assembly.builders")
require("scripts.assembly.placement")
require("scripts.assembly.events")

--------------------------------------------------------------------------------
-- Initiation of the class
--------------------------------------------------------------------------------
function Trainassembly:onInit()
  -- Init global data; data stored through the whole map
  if not storage.TA_data then
    storage.TA_data = self:initGlobalData()
  end
end



-- Initiation of the global data
function Trainassembly:initGlobalData()
  local TA_data = {
    ["version"] = 8, -- version of the global data
    ["prototypeData"] = self:initPrototypeData(), -- data storing info about the prototypes

    ["trainAssemblers"] = {}, -- keep track of all assembling machines

    ["trainBuilders"] = {}, -- keep track of all builders that contain one or more trainAssemblers
    ["nextTrainBuilderIndex"] = 1, -- next free space in the trainBuilders table
    ["fuelItems"] = {}, -- cache to more efficiently decide if an item is fuel or not
  }

  return util.table.deepcopy(TA_data)
end



-- Initialisation of the prototye data inside the global data
function Trainassembly:initPrototypeData()
  return
  {
    ["itemName"     ] = "trainassembly",           -- the item
    ["placeableName"] = "trainassembly-placeable", -- locomotive entity
    ["machineName"  ] = "trainassembly-machine",   -- assembling entity

    ["trainTint"    ] = {},                        -- the tint of each created entity
    ["rollingStock" ] = {                          -- the types of rolling stocks
      ["locomotive"     ] = true,
      ["cargo-wagon"    ] = true,
      ["fluid-wagon"    ] = true,
      ["artillery-wagon"] = true,
    },
  }
end
