---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller.Gui: Fenster des Controllers. Teile: click-handlers, window.

local trainControllerGui = require("prototypes.gui.layout.traincontroller")

-- Create class
Traincontroller.Gui = {}
Traincontroller.Gui.rotateEventID = script.generate_event_name()

--------------------------------------------------------------------------------
-- Initiation of the class
--------------------------------------------------------------------------------
function Traincontroller.Gui:onInit()
  if not storage.TC_data.Gui then
    storage.TC_data.Gui = self:initGlobalData()
    self:initEntityPreviewSurface()
  end
end



-- Initiation of the global data
function Traincontroller.Gui:initGlobalData()
  local gui = {
    ["version"       ] = 8, -- version of the global data
    ["surfaceName"   ] = "trainConstructionSite",
    ["prototypeData" ] = self:initPrototypeData(), -- data storing info about the prototypes
    ["openedEntities"] = {}, -- opened entity for each player
  }

  return util.table.deepcopy(gui)
end



function Traincontroller.Gui:initPrototypeData()
  -- tabButtonPath
  local tabButtonPath = {}
  for _,tabButtonName in pairs{
    "traincontroller-tab-selection" ,
    "traincontroller-tab-statistics",
  } do
    tabButtonPath[tabButtonName] = FLib.gui.layout.getElementPath(trainControllerGui, tabButtonName)
  end

  -- updateElementPath
  local updateElementPath = {}
  for _,selectionTabElementName in pairs{
    "selected-depot-name", -- current/new depot name
    "selected-depot-list", -- list of all depot names
  } do
    updateElementPath[selectionTabElementName] = FLib.gui.layout.getElementPath(trainControllerGui, selectionTabElementName)
  end
  for _,statisticsTabElementName in pairs{
    "statistics-station-id-value"                , -- controller name
    "statistics-depot-request-value"             , -- depot request amount
    "statistics-builder-status-value"            , -- controller status
    "statistics-builder-configuration-flow"      , -- controller configuration

    "traincontroller-color-picker"               , -- color picking frame
    "traincontroller-color-picker-entity-preview", -- color picker entity preview
  } do
    updateElementPath[statisticsTabElementName] = FLib.gui.layout.getElementPath(trainControllerGui, statisticsTabElementName)
  end

  return {
    -- gui layout
    ["trainControllerGui"] = trainControllerGui,

    -- gui element paths (derived from layout)
    ["tabButtonPath"     ] = tabButtonPath     ,
    ["updateElementPath" ] = updateElementPath ,

    ["recipeSelector"    ] = Trainassembly:getMachineEntityName() .. "-recipe-selector"
  }
end



function Traincontroller.Gui:initEntityPreviewSurface()
  if not game.surfaces[self:getControllerSurfaceName()] then
    game.create_surface(self:getControllerSurfaceName(), {
      -- TERRAIN SPECIFICATION --
      terrain_segmentation = 0,
      water = 0, -- no water
      width  = 0, -- infinite
      height = 10,

      -- AUTOPLACE SETTINGS --
      autoplace_controls = nil,
      default_enable_all_autoplace_controls = false, -- autoplace not set, disallow to get default controls
      autoplace_settings = nil,
      cliff_settings = nil, -- no cliffs
      seed   = 0, -- doesn't matter, just has to be something

      starting_area   = 0,    -- no starting area generation procedure
      starting_points = {},   -- no starting points on this map
      peaceful_mode   = true, -- doesn't mater, no biters are autoplaced

      property_expression_names = {
        ["moisture"            ] = 1,
        ["aux"                 ] = .5,
        ["temperature"         ] = -20,
        ["elevation"           ] = 1,
        ["cliffiness"          ] = 0,
        ["enemy-base-intensity"] = 0,
        ["enemy-base-frequency"] = 0,
        ["enemy-base-radius"   ] = 0
      },
    })

    for playerIndex,_ in pairs(game.players) do
      self:initEntityPreviewPlayer(playerIndex)
    end
  end
end



function Traincontroller.Gui:initEntityPreviewPlayer(playerIndex)
  local radius = 10
  local surface = game.surfaces[self:getControllerSurfaceName()]

  for x = -radius, radius, 2 do
    surface.create_entity{
      name = "straight-rail",
      position = {
        x = x + 3*radius*playerIndex,
        y = 0
      },
      direction = defines.direction.east,
      force = game.get_player(playerIndex).force,
      player = playerIndex,
    }
  end
end



--------------------------------------------------------------------------------
-- Setter functions to alter data into the data structure
--------------------------------------------------------------------------------
function Traincontroller.Gui:setOpenedControllerEntity(playerIndex, openedEntity)
  if not storage.TC_data.Gui["openedEntities"][playerIndex] then
    storage.TC_data.Gui["openedEntities"][playerIndex] = {}
  end
  storage.TC_data.Gui["openedEntities"][playerIndex]["traincontroller"] = openedEntity
end



function Traincontroller.Gui:setOpenedRecipeEntity(playerIndex, openedEntity)
  if not storage.TC_data.Gui["openedEntities"][playerIndex] then
    storage.TC_data.Gui["openedEntities"][playerIndex] = {}
  end
  storage.TC_data.Gui["openedEntities"][playerIndex]["traincontroller-recipe"] = openedEntity
end



--------------------------------------------------------------------------------
-- Getter functions to extract data from the data structure
--------------------------------------------------------------------------------
function Traincontroller.Gui:getControllerSurfaceName()
  return storage.TC_data.Gui["surfaceName"]
end



function Traincontroller.Gui:getControllerGuiLayout()
  return storage.TC_data.Gui["prototypeData"]["trainControllerGui"]
end



function Traincontroller.Gui:getRecipeSelectorEntityName()
  return storage.TC_data.Gui["prototypeData"]["recipeSelector"]
end



function Traincontroller.Gui:getTabElementPath(guiElementName)
  return storage.TC_data.Gui["prototypeData"]["tabButtonPath"][guiElementName]
end


function Traincontroller.Gui:getUpdateElementPath(guiElementName)
  return storage.TC_data.Gui["prototypeData"]["updateElementPath"][guiElementName]
end



function Traincontroller.Gui:getRotateEventID()
  return Traincontroller.Gui.rotateEventID
end



function Traincontroller.Gui:getClickHandler(guiElementName)
  return Traincontroller.Gui.clickHandlers[guiElementName]
end



function Traincontroller.Gui:getGuiName()
  return FLib.gui.getRootElementName(self:getControllerGuiLayout())
end



function Traincontroller.Gui:getOpenedControllerStatusString(playerIndex)
  local controllerStatus = Traincontroller.Builder:getControllerStatus(self:getOpenedControllerEntity(playerIndex))
  local controllerStates  = storage.TC_data.Builder["builderStates"]

  if controllerStatus == controllerStates["idle"] then
    -- wait until a depot request a train
    return {"gui-traincontroller.controller-status-wait-to-dispatch"}

  elseif controllerStatus == controllerStates["building"] then
    -- waiting on resources, building each component
    return {"gui-traincontroller.controller-status-building-train"}

  elseif controllerStatus == controllerStates["dispatching"] then
    -- waiting till previous train clears the train block
    return {"gui-traincontroller.controller-status-ready-to-dispatch"}

  elseif controllerStatus == controllerStates["dispatch"] then
    -- assembling the train components together and let the train drive off
    return {"gui-traincontroller.controller-status-ready-to-dispatch"}

  else return "undefined status" end
end



function Traincontroller.Gui:getOpenedControllerEntity(playerIndex)
  if storage.TC_data.Gui["openedEntities"][playerIndex] then
    return storage.TC_data.Gui["openedEntities"][playerIndex]["traincontroller"]
  else
    return nil
  end
end



function Traincontroller.Gui:getOpenedRecipeEntity(playerIndex)
  if storage.TC_data.Gui["openedEntities"][playerIndex] then
    return storage.TC_data.Gui["openedEntities"][playerIndex]["traincontroller-recipe"]
  else
    return nil
  end
end



function Traincontroller.Gui:hasOpenedGui(playerIndex)
  return self:getOpenedControllerEntity(playerIndex) and true or false
end

require("scripts.gui.controller.click-handlers")
require("scripts.gui.controller.click-handlers-color")
-- erst jetzt, wenn alle Handler bekannt sind
Traincontroller.Gui.clickHandlers = Traincontroller.Gui:initClickHandlers()
require("scripts.gui.controller.window")
