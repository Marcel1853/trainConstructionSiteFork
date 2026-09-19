---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller: der Controller (Zughalt) am Ende eines Trainbuilders.
-- Teile: structure, getters, placement, pending (auf Builder wartende Controller), events,
-- builder + build-train (Zug bauen und losschicken), GUI in scripts/gui/controller/.

Traincontroller = {}
require("scripts.controller.structure")
require("scripts.controller.getters")
require("scripts.controller.placement")
require("scripts.controller.pending")
require("scripts.controller.events")
require("scripts.controller.builder")
require("scripts.controller.build-train")
require("scripts.gui.controller.init")

--------------------------------------------------------------------------------
-- Initiation of the class
--------------------------------------------------------------------------------
function Traincontroller:onInit()
  -- Init global data; data stored through the whole map
  if not storage.TC_data then
    storage.TC_data = self:initGlobalData()
  end
  self:createControllerForces()
  self.Builder:onInit()
  self.Gui:onInit()
end

function Traincontroller:onLoad()
  -- Sync global state on multiplayer, make sure event handlers are set correctly
  self.Builder:onLoad()
  self:syncPendingControllerTick()
end

function Traincontroller:onSettingChanged(event)
  -- called when a mod setting changed
  self.Builder:onSettingChanged(event)
end

-- Initiation of the global data
function Traincontroller:initGlobalData()
  local TC_data = {
    ["version"] = 4,                                           -- version of the global data
    ["prototypeData"] = self:initPrototypeData(),              -- data storing info about the prototypes

    ["trainControllerForces"] = {},                            -- keep track of the created forces
    ["trainControllerNamesCount"] = {},                        -- keep track of the depos the controllers are using

    ["trainControllers"] = {},                                 -- keep track of all controllers
    ["nextTrainControllerIterate"] = nil,                      -- next controller to iterate over
    ["pendingControllers"] = {},                               -- robot/blueprint built controllers waiting for surrounding entities
  }

  return util.table.deepcopy(TC_data)
end

-- Initialisation of the prototye data inside the global data
function Traincontroller:initPrototypeData()
  return
  {
    ["trainControllerName"] = "traincontroller",                -- item and entity have same name
    ["trainControllerSignalName"] = "traincontroller-signal",   -- hidden signals
    ["trainControllerMapviewName"] = "traincontroller-mapview", -- simple entity

    ["trainControllerForce"] = "-trainControllerForce",         -- force for the traincontrollers
  }
end

-- Create force for traincontrollers
function Traincontroller:createControllerForces()
  local forcesToCreate = {}

  -- get a list for all the forces to create
  for forceName, _ in pairs(game.forces) do
    if forceName ~= "enemy" and forceName ~= "neutral" then
      table.insert(forcesToCreate, forceName)
    end
  end

  -- create all the forces
  for _, forceName in pairs(forcesToCreate) do
    -- create the force and set it friendly
    local friendlyForceName = self:getControllerForceName(forceName)
    if not game.forces[friendlyForceName] then
      game.create_force(friendlyForceName).set_friend(forceName, true)
      game.forces[forceName].set_friend(friendlyForceName, true)
    end

    -- save the created force in the data structure
    storage.TC_data["trainControllerForces"][friendlyForceName] = forceName
  end
end
