---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller.Builder: Zustandsautomat je Controller. Der Takt liegt in scripts/core/heartbeat.lua.

-- Create class
Traincontroller.Builder = {}

--------------------------------------------------------------------------------
-- Initiation of the class
--------------------------------------------------------------------------------
function Traincontroller.Builder:onInit()
  if not storage.TC_data.Builder then
    storage.TC_data.Builder = self:initGlobalData()
  end
end

function Traincontroller.Builder:onLoad()
  -- the heartbeat registers itself again, see scripts/core/heartbeat.lua
  Heartbeat:onLoad()
end

-- called when a mod setting changed
function Traincontroller.Builder:onSettingChanged(event)
  -- check if the tickrate has changed
  if event.setting_type == "runtime-global" and event.setting == "trainController-tickRate" then
    storage.TC_data.Builder["onTickDelay"] = settings.global[event.setting].value
    Heartbeat:sync() -- meldet den Takt mit der neuen Zahl neu an
  end
end

-- Initiation of the global data
function Traincontroller.Builder:initGlobalData()
  local Builder = {
    ["version"] = 1,          -- version of the global data
    ["onTickActive"] = false, -- if the on_tick event is active or not
    ["onTickDelay"] = settings.global["trainController-tickRate"].value,

    ["builderStates"] = {   -- states in the builder process
      ["initialState"] = 1, -- what state the controller is in when it is placed down

      ["dispatching"] = 1,  -- waiting till previous train clears the train block
      ["building"] = 2,     -- waiting on resources, building each component
      ["idle"] = 3,         -- wait until a depot request a train
      ["dispatch"] = 4,     -- assembling the train components together and let the train drive off
    },
  }

  return util.table.deepcopy(Builder)
end

function Traincontroller.Builder:getControllerStatus(trainController)
  local position = trainController.position
  return storage.TC_data["trainControllers"][trainController.surface.index][position.y][position.x]["controllerStatus"]
end

--------------------------------------------------------------------------------
-- Behaviour functions
--------------------------------------------------------------------------------
function Traincontroller.Builder:updateController(surfaceIndex, position)
  -- This function will check the update for a single controller
  --game.print("Updating controller @ ["..surfaceIndex..", "..position.x..", "..position.y.."]")
  local controllerData      = storage.TC_data["trainControllers"][surfaceIndex][position.y][position.x]
  local controllerStates    = storage.TC_data.Builder["builderStates"]
  local controllerStatus    = controllerData["controllerStatus"]
  local oldControllerStatus = controllerStatus
  local controllerEntity    = controllerData["entity"]
  local trainBuilderIndex   = controllerData["trainBuilderIndex"]


  if controllerStatus == controllerStates["dispatching"] then
    -- controller is waiting till previous train clears the train block
    if self:canBuildNextTrain(trainBuilderIndex, controllerEntity) then
      -- if we can build a new train, we move on to the next step
      --game.print("Start building a train of length: "..#Trainassembly:getTrainBuilder(trainBuilderIndex))
      controllerStatus = controllerStates["building"]
    end
  end


  if controllerStatus == controllerStates["building"] then
    -- controller is waiting on resources, building each component
    if self:buildNextTrain(trainBuilderIndex) then
      -- if the whole train is build, we can send it away
      --game.print("Finished building a train of length: "..#Trainassembly:getTrainBuilder(trainBuilderIndex))
      controllerStatus = controllerStates["idle"]
    end
  end


  if controllerStatus == controllerStates["idle"] then
    -- controller is waiting to send the train away
    if self:depotIsRequestingTrain(controllerEntity) then
      -- if a depot is requesting a train, we can send it away
      --game.print("Ready to dispatch a train of length: "..#Trainassembly:getTrainBuilder(trainBuilderIndex))
      controllerStatus = controllerStates["dispatch"]
    end
  end


  if controllerStatus == controllerStates["dispatch"] then
    -- assembling the train components together and let the train drive off
    if self:assembleNextTrain(trainBuilderIndex, controllerEntity.backer_name) then
      -- update all traincontrollers with this name
      local trainControllers = Traincontroller:getAllTrainControllers(controllerEntity.surface.index,
        controllerEntity.backer_name)
      for _, trainController in pairs(trainControllers) do
        Traincontroller.Gui:updateOpenedGuis(trainController, false)
      end
      --game.print("Leaving train of length: "..#Trainassembly:getTrainBuilder(trainBuilderIndex))
      controllerStatus = controllerStates["dispatching"]
    end
  end


  -- the controller could have been removed
  if storage.TC_data["trainControllers"] and
      storage.TC_data["trainControllers"][surfaceIndex] and
      storage.TC_data["trainControllers"][surfaceIndex][position.y] and
      storage.TC_data["trainControllers"][surfaceIndex][position.y][position.x] then
    -- save changes to the global data before any gui updates
    storage.TC_data["trainControllers"][surfaceIndex][position.y][position.x]["controllerStatus"] = controllerStatus

    -- update the gui if needed
    if controllerStatus ~= oldControllerStatus then
      Traincontroller.Gui:updateOpenedGuis(controllerEntity)
    end
  end
end

--------------------------------------------------------------------------------
-- Event interface
--------------------------------------------------------------------------------
function Traincontroller.Builder:onTick(event)
  -- Extract the controller that needs to be updated
  local controller = util.table.deepcopy(storage.TC_data["nextTrainControllerIterate"])
  if not controller then return end -- nothing to do
  local surfaceIndex   = controller.surfaceIndex
  local position       = controller.position

  -- the entry can be gone already (controller removed in between)
  local surfaceData = storage.TC_data["trainControllers"][surfaceIndex]
  local row = surfaceData and surfaceData[position.y]
  local controllerData = row and row[position.x]
  if not controllerData then
    storage.TC_data["nextTrainControllerIterate"] = nil
    Heartbeat:sync()
    return
  end

  -- extract the next controller
  local nextController = util.table.deepcopy(controllerData["nextController"])

  -- Update the controller
  self:updateController(surfaceIndex, position)

  -- Increment the nextController
  if FLib.utils.table.areEqual(controller, storage.TC_data["nextTrainControllerIterate"]) then
    storage.TC_data["nextTrainControllerIterate"] = nextController
  end
end

-- Alte Namen, damit ältere Aufrufe weiter stimmen: beides regelt jetzt der Heartbeat.
function Traincontroller.Builder:activateOnTick()
  Heartbeat:sync()
end

function Traincontroller.Builder:deactivateOnTick()
  Heartbeat:sync()
end
