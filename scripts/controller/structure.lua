---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller: Controller speichern und löschen (verkettete Liste), Zughalt einstellen, umbenennen.

local trainRecipe = require("compat.train_recipe")

--------------------------------------------------------------------------------
-- Setter functions to alter data into the data structure
--------------------------------------------------------------------------------
function Traincontroller:saveNewStructure(controllerEntity, trainBuilderIndex)
  -- With this function we save all the data we want about a traincontroller.
  -- This traincontroller will be used to iterate over all the trainbuilders,
  -- this means they will be added to a linked list, with other words, each
  -- entry knows what controller is before or afther itself.

  -- STEP 1: We can already store the wanted data in the structure
  -- STEP 1a:Make sure we can index it, meaning, check if the table already
  --         excists for the surface, if not, we make one. Afther that we also
  --         have to check if the surface table has a table we can index for
  --         the y-position, if not, we make one.
  local controllerSurface  = controllerEntity.surface
  local controllerPosition = controllerEntity.position
  if not storage.TC_data["trainControllers"][controllerSurface.index] then
    storage.TC_data["trainControllers"][controllerSurface.index] = {}
  end
  if not storage.TC_data["trainControllers"][controllerSurface.index][controllerPosition.y] then
    storage.TC_data["trainControllers"][controllerSurface.index][controllerPosition.y] = {}
  end

  -- STEP 1b:Now we know we can index (without crashing) to the position as:
  --         dataStructure[surfaceIndex][positionY][positionX]
  --         Now we can store our wanted data at this position
  storage.TC_data["trainControllers"][controllerSurface.index][controllerPosition.y][controllerPosition.x] =
  {
    ["entity"]            = controllerEntity,                                        -- the controller entity
    ["entity-hidden"]     = {},                                                      -- the hidden entities

    ["trainBuilderIndex"] = trainBuilderIndex,                                       -- the trainbuilder it controls
    ["controllerStatus"]  = storage.TC_data.Builder["builderStates"]["initialState"], -- status

    -- list data
    ["prevController"]    = nil, -- the previous controller
    ["nextController"]    = nil, -- the next controller
  }

  -- STEP 2: We need to add this controller to the chain of the linked list
  local thisController = {
    ["surfaceIndex"] = controllerSurface.index,
    ["position"]     = controllerPosition,
  }

  if not storage.TC_data["nextTrainControllerIterate"] then
    -- STEP 2a: When it is the first one, it is easy to add, since its the first
    storage.TC_data["nextTrainControllerIterate"] = thisController
    storage.TC_data["trainControllers"][thisController["surfaceIndex"]][thisController["position"].y][thisController["position"].x]["prevController"] =
    util.table.deepcopy(thisController)
    storage.TC_data["trainControllers"][thisController["surfaceIndex"]][thisController["position"].y][thisController["position"].x]["nextController"] =
    util.table.deepcopy(thisController)

    -- STEP 2b: start on_tick events becose we need to start iterating
    self.Builder:activateOnTick()
  else
    -- when we've added it to the list, we know there is at least one in front
    -- of us. This one has a prev set. We add it inbetween.

    -- STEP 2a: extract the previous and next controller
    local nextController = storage.TC_data["nextTrainControllerIterate"]
    local prevController = storage.TC_data["trainControllers"][nextController["surfaceIndex"]]
    [nextController["position"].y][nextController["position"].x]["prevController"]

    -- STEP 2b: adapt the previous controller
    storage.TC_data["trainControllers"][prevController["surfaceIndex"]][prevController["position"].y][prevController["position"].x]["nextController"] =
    util.table.deepcopy(thisController)
    storage.TC_data["trainControllers"][thisController["surfaceIndex"]][thisController["position"].y][thisController["position"].x]["prevController"] =
    util.table.deepcopy(prevController)

    -- STEP 2c: adapt the next controller
    storage.TC_data["trainControllers"][nextController["surfaceIndex"]][nextController["position"].y][nextController["position"].x]["prevController"] =
    util.table.deepcopy(thisController)
    storage.TC_data["trainControllers"][thisController["surfaceIndex"]][thisController["position"].y][thisController["position"].x]["nextController"] =
    util.table.deepcopy(nextController)

    -- STEP 2d: make sure the next iteration doesn't skip this new controller
    if FLib.utils.table.areEqual(storage.TC_data["nextTrainControllerIterate"], nextController) then
      storage.TC_data["nextTrainControllerIterate"] = util.table.deepcopy(thisController)
    end
  end

  -- STEP 3: Configure the controller
  -- STEP 3a:Create hidden entities (2 rail signals)
  local hiddenEntities = storage.TC_data["trainControllers"][controllerSurface.index][controllerPosition.y]
  [controllerPosition.x]["entity-hidden"]
  for hiddenEntityIndex, hiddenEntityData in pairs(self:getHiddenEntityData(controllerPosition, controllerEntity.direction)) do
    hiddenEntities[hiddenEntityIndex] = controllerSurface.create_entity {
      name      = hiddenEntityData.name,
      position  = hiddenEntityData.position,
      direction = hiddenEntityData.direction,
      force     = controllerEntity.force
    }
  end

  -- STEP 3b:The controller needs to be on another (friendly) force. This way
  --         the controller wont show up on the train menu.
  local controllerForceName = self:getControllerForceName(controllerEntity.force.name)
  controllerEntity.force = controllerForceName

  -- STEP 3c:The controller needs to be disabled. This way the trains won't path
  --         to this stop. To get this behaviour, we connect it to the logistics
  --         network and make sure it has a disabled condition
  self:setTrainstopControlBehaviour(controllerEntity)
  --game.print(serpent.block(storage.TC_data["trainControllers"]))

  -- STEP 3c:Keep track how many controllers are connected to a depot
  if not storage.TC_data["trainControllerNamesCount"][controllerForceName] then
    storage.TC_data["trainControllerNamesCount"][controllerForceName] = {}
  end
  if not storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurface.index] then
    storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurface.index] = {}
  end

  local stationName = controllerEntity.backer_name
  local stationAmount = storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurface.index]
  [stationName] or 0
  storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurface.index][stationName] = stationAmount +
  1
end

function Traincontroller:deleteController(controllerEntity)
  -- STEP 1a: make sure we can index the table
  --local controllerSurface = controllerEntity.surface
  local controllerSurfaceIndex = controllerEntity.surface.index
  local controllerPosition = controllerEntity.position
  if not storage.TC_data["trainControllers"][controllerSurfaceIndex] then
    return
  end
  if not storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y] then
    return
  end
  if not storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y][controllerPosition.x] then
    return
  end

  -- STEP 1b: destroy the hidden entities
  for _, entity in pairs(storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y][controllerPosition.x]["entity-hidden"] or {}) do
    if entity.valid then entity.destroy() end
  end

  -- STEP 2: remove this controller from the list
  local thisController = {
    ["surfaceIndex"] = controllerSurfaceIndex,
    ["position"]     = controllerPosition,
  }

  -- STEP 2a: extract the previous and next controller
  local prevController = storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y]
  [controllerPosition.x]["prevController"]
  local nextController = storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y]
  [controllerPosition.x]["nextController"]

  -- Entry of a neighbour in the list, nil if the list is broken (old saves)
  local function listEntry(listController)
    if not listController then return nil end
    local surfaceData = storage.TC_data["trainControllers"][listController["surfaceIndex"]]
    local row = surfaceData and surfaceData[listController["position"].y]
    return row and row[listController["position"].x]
  end

  -- STEP 2b: adapt the prevController
  local prevEntry = listEntry(prevController)
  if prevEntry then prevEntry["nextController"] = util.table.deepcopy(nextController) end

  -- STEP 2c: adapt the next controller
  local nextEntry = listEntry(nextController)
  if nextEntry then nextEntry["prevController"] = util.table.deepcopy(prevController) end

  -- STEP 2d: make sure the next iteration does skip this old controller
  if FLib.utils.table.areEqual(storage.TC_data["nextTrainControllerIterate"], thisController) then
    -- Make sure the next controller isn't this controller, then there are no controllers.
    if FLib.utils.table.areEqual(thisController, nextController) then
      storage.TC_data["nextTrainControllerIterate"] = nil
      -- this is the last one, no need to keep iterating on_tick
      self.Builder:deactivateOnTick()
    else
      storage.TC_data["nextTrainControllerIterate"] = util.table.deepcopy(nextController)
    end
  end

  -- STEP 2e: Delete this controller
  storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y][controllerPosition.x] = nil

  if FLib.utils.table.isEmpty(storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y]) then
    storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y] = nil
  end
  if FLib.utils.table.isEmpty(storage.TC_data["trainControllers"][controllerSurfaceIndex]) then
    storage.TC_data["trainControllers"][controllerSurfaceIndex] = nil
  end
  --game.print(serpent.block(storage.TC_data["trainControllers"]))


  -- STEP 3: remove this controller from the depot list
  local controllerForceName = controllerEntity.force.name

  local stationName = controllerEntity.backer_name
  local forceNamesCount = storage.TC_data["trainControllerNamesCount"][controllerForceName]
  local stationAmount = forceNamesCount and forceNamesCount[controllerSurfaceIndex] and
                        forceNamesCount[controllerSurfaceIndex][stationName]

  if stationAmount then
    if stationAmount > 1 then
      storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex][stationName] =
      stationAmount - 1
    else
      storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex][stationName] = nil

      if FLib.utils.table.isEmpty(storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex]) then
        storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex] = nil

        if FLib.utils.table.isEmpty(storage.TC_data["trainControllerNamesCount"][controllerForceName]) then
          storage.TC_data["trainControllerNamesCount"][controllerForceName] = nil
        end
      end
    end
  end

  -- Update the UI
  controllerEntity.health = 0 -- set health to 0, otherwise it's not working
  self.Gui:updateOpenedGuis(controllerEntity)
end

function Traincontroller:setTrainstopControlBehaviour(trainStopEntity)
  local stationBehaviour                       = trainStopEntity.get_or_create_control_behavior()
  -- https://lua-api.factorio.com/latest/LuaControlBehavior.html#LuaTrainStopControlBehavior
  stationBehaviour.send_to_train               = false         -- sending signals to the train
  stationBehaviour.read_from_train             = false         -- reading train content from the train
  stationBehaviour.read_stopped_train          = false         -- read train id from the train
  stationBehaviour.circuit_enable_disable      = false         -- open/close train station with circuit network
  stationBehaviour.connect_to_logistic_network = true          -- open/close train station with logistic network

  -- enable/disable condition for circuit network
  stationBehaviour.circuit_condition           = {
    -- https://lua-api.factorio.com/latest/LuaControlBehavior.html#LuaGenericOnOffControlBehavior.circuit_condition
    comparator    = "<",
    first_signal  = nil, -- blank, no condition set
    second_signal = nil, -- if not set, it will compare to constant
    constant      = nil, -- if not set, will default to 0
  }

  -- make sure it is disconnected from the logistics network
  stationBehaviour.logistic_condition          = {
    -- https://lua-api.factorio.com/latest/LuaControlBehavior.html#LuaGenericOnOffControlBehavior.logistic_condition
    comparator    = "<",
    first_signal  = nil, -- blank, no condition set
    second_signal = nil, -- if not set, it will compare to constant
    constant      = nil, -- if not set, will default to 0
  }
end

function Traincontroller:setDefaultMachineTints(builderIndex)
  -- set the default machine tints depending on the recipe
  for _, builderLocation in pairs(Trainassembly:getTrainBuilder(builderIndex)) do
    local builderEntity = Trainassembly:getMachineEntity(builderLocation["surfaceIndex"], builderLocation["position"])
    if builderEntity and builderEntity.valid then
      local builderRecipe = builderEntity.get_recipe()
      if builderRecipe then
        local buildEntityName = trainRecipe.parse_name(builderRecipe.name)
        if buildEntityName then
          Trainassembly:setMachineTint(builderEntity, Trainassembly:getTrainTint(buildEntityName))
        end
      end
    end
  end
end

function Traincontroller:deleteBuildTrain(builderIndex)
  -- delete the whole created train from a builder
  for _, builderLocation in pairs(Trainassembly:getTrainBuilder(builderIndex)) do
    Trainassembly:deleteCreatedTrainEntity(builderLocation["surfaceIndex"], builderLocation["position"])
  end
end

function Traincontroller:renameBuilding(controllerEntity, oldName)
  local stationName = controllerEntity.backer_name
  if oldName ~= stationName then -- checking to make sure it is actualy changed
    local controllerForceName = controllerEntity.force.name
    local controllerSurfaceIndex = controllerEntity.surface.index

    -- remove the old one
    local stationAmount = storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex]
    [oldName]
    if stationAmount then
      if stationAmount > 1 then
        storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex][oldName] =
        stationAmount - 1
      else
        storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex][oldName] = nil
        -- no need to delete empty tables, since we'll be adding one to it again
      end
    end

    -- add the new one
    stationAmount = storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex]
    [stationName] or 0
    storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex][stationName] =
    stationAmount + 1

    -- update the ui
    Traindepot.Gui:updateOpenedGuis(oldName)
    self.Gui:updateOpenedGuis(controllerEntity)
  end
end
