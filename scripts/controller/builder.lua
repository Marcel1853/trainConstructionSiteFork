---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller.Builder: Heartbeat (on_nth_tick) und Zustandsautomat je Controller.

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
  -- sync the on tick event
  if storage.TC_data.Builder["onTickActive"] then
    self:activateOnTick()
  else
    self:deactivateOnTick()
  end
end

-- called when a mod setting changed
function Traincontroller.Builder:onSettingChanged(event)
  -- check if the tickrate has changed
  if event.setting_type == "runtime-global" and event.setting == "trainController-tickRate" then
    -- we need to update the on_nth_tick event (step 2), but we fist need to
    -- disable the old one if it was active (step 1), and if it was active,
    -- we have to reactivate it afther updating the settings (step 3)
    local onTickWasActive = storage.TC_data.Builder["onTickActive"]

    -- STEP 1: disable the old active on_tick
    if onTickWasActive then
      self:deactivateOnTick()
    end

    -- STEP 2: update the settings
    storage.TC_data.Builder["onTickDelay"] = settings.global[event.setting].value

    -- STEP 3: reactivate the on_tick with new settings
    if onTickWasActive then
      self:activateOnTick()
    end
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
  --game.print(game.tick)

  -- Extract the controller that needs to be updated
  local controller     = util.table.deepcopy(storage.TC_data["nextTrainControllerIterate"])
  local surfaceIndex   = controller.surfaceIndex
  local position       = controller.position

  -- extract the next controller
  local nextController = util.table.deepcopy(
    storage.TC_data["trainControllers"][controller.surfaceIndex][controller.position.y][controller.position.x]
    ["nextController"]
  )

  -- Update the controller
  self:updateController(surfaceIndex, position)

  -- Increment the nextController
  if FLib.utils.table.areEqual(controller, storage.TC_data["nextTrainControllerIterate"]) then
    storage.TC_data["nextTrainControllerIterate"] = nextController
  end
end

function Traincontroller.Builder:activateOnTick()
  --game.print("on_tick activated")
  script.on_nth_tick(storage.TC_data.Builder["onTickDelay"], function(event)
    self:onTick(event)
  end)
  storage.TC_data.Builder["onTickActive"] = true
end

function Traincontroller.Builder:deactivateOnTick()
  --game.print("on_tick deactivated")
  script.on_nth_tick(storage.TC_data.Builder["onTickDelay"], nil)
  storage.TC_data.Builder["onTickActive"] = false
end
