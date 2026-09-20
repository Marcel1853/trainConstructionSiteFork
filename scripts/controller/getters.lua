---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller: Namen, Forces und Daten aus storage lesen.

--------------------------------------------------------------------------------
-- Getter functions to extract data from the data structure
--------------------------------------------------------------------------------
function Traincontroller:getControllerItemName()
  return storage.TC_data.prototypeData.trainControllerName
end

function Traincontroller:getControllerEntityName()
  return storage.TC_data.prototypeData.trainControllerName
end

function Traincontroller:getControllerMapviewEntityName()
  return storage.TC_data.prototypeData.trainControllerMapviewName
end

function Traincontroller:getControllerSignalEntityName()
  return storage.TC_data.prototypeData.trainControllerSignalName
end

function Traincontroller:getControllerForceName(depotForceName)
  return depotForceName .. storage.TC_data.prototypeData.trainControllerForce
end

function Traincontroller:getDepotForceName(controllerForceName)
  return controllerForceName:sub(1, -(storage.TC_data.prototypeData.trainControllerForce:len() + 1))
end

function Traincontroller:getTrainController(trainBuilderIndex)
  -- without an index every controller whose index is not set yet would match
  if not trainBuilderIndex then return nil end
  for surfaceIndex, _ in pairs(storage.TC_data["trainControllers"]) do
    for positionY, _ in pairs(storage.TC_data["trainControllers"][surfaceIndex]) do
      for positionX, _ in pairs(storage.TC_data["trainControllers"][surfaceIndex][positionY]) do
        local trainController = storage.TC_data["trainControllers"][surfaceIndex][positionY][positionX]

        if trainController["trainBuilderIndex"] == trainBuilderIndex then
          return trainController["entity"]
        end
      end
    end
  end

  return nil
end

function Traincontroller:getControllerEntity(controllerSurfaceIndex, controllerPosition)
  if storage.TC_data["trainControllers"][controllerSurfaceIndex] and
      storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y] and
      storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y][controllerPosition.x] then
    return storage.TC_data["trainControllers"][controllerSurfaceIndex][controllerPosition.y][controllerPosition.x]
    ["entity"]
  else
    return nil
  end
end

function Traincontroller:getAllTrainControllers(surfaceIndex, controllerName)
  if not storage.TC_data["trainControllers"][surfaceIndex] then return {} end

  local entities = {}
  local entityIndex = 1
  for posY, posYdata in pairs(storage.TC_data["trainControllers"][surfaceIndex]) do
    for posX, trainController in pairs(posYdata) do
      local entity = trainController["entity"]
      if entity.backer_name == controllerName then
        entities[entityIndex] = entity
        entityIndex = entityIndex + 1
      end
    end
  end

  return entities
end

function Traincontroller:getTrainBuilderIndex(trainController)
  local surfaceIndex = trainController.surface.index
  local position     = trainController.position

  -- STEP 1: make sure we can index the datastructure
  if not storage.TC_data["trainControllers"][surfaceIndex] then
    return nil
  end
  if not storage.TC_data["trainControllers"][surfaceIndex][position.y] then
    return nil
  end
  if not storage.TC_data["trainControllers"][surfaceIndex][position.y][position.x] then
    return nil
  end

  -- STEP 2: return the tainBuilderIndex
  return storage.TC_data["trainControllers"][surfaceIndex][position.y][position.x]["trainBuilderIndex"]
end

function Traincontroller:hasTrainBuilderEntities(controllerForceName, controllerSurfaceIndex)
  -- returns true if at least one depot has been build on the force on that surface
  if storage.TC_data["trainControllerNamesCount"][controllerForceName] and
      storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex] then
    return not FLib.utils.table.isEmpty(storage.TC_data["trainControllerNamesCount"][controllerForceName]
    [controllerSurfaceIndex])
  end
  return false
end

function Traincontroller:getTrainBuilderNames(controllerForceName, controllerSurfaceIndex)
  if self:hasTrainBuilderEntities(controllerForceName, controllerSurfaceIndex) then
    return storage.TC_data["trainControllerNamesCount"][controllerForceName][controllerSurfaceIndex]
  else
    return {}
  end
end

function Traincontroller:getTrainBuilderCount(controllerForceName, controllerSurfaceIndex, controllerName)
  return self:getTrainBuilderNames(controllerForceName, controllerSurfaceIndex)[controllerName] or 0
end

-- Trägt der Controller bereits einen Namen, der etwas bedeutet? Das ist der Fall, wenn es ein
-- Depot dieses Namens gibt oder schon ein anderer Controller so heißt (Kopie einer Anlage).
-- Nur dann darf der Name beim Bauen nicht durch den Standardnamen ersetzt werden.
function Traincontroller:hasUsefulStationName(controllerEntity)
  local stationName = controllerEntity.backer_name
  if not stationName or stationName == "" then return false end

  local depotForceName = storage.TC_data["trainControllerForces"][controllerEntity.force.name] or
                         controllerEntity.force.name
  local surfaceIndex = controllerEntity.surface.index
  if Traindepot:getDepotStationCount(depotForceName, surfaceIndex, stationName) > 0 then
    return true
  end
  return self:getTrainBuilderCount(self:getControllerForceName(depotForceName), surfaceIndex, stationName) > 0
end

function Traincontroller:getTrainHiddenEntity(controllerEntity, hiddenEntityIndex)
  local surfaceData = storage.TC_data["trainControllers"][controllerEntity.surface.index]
  local row = surfaceData and surfaceData[controllerEntity.position.y]
  local controllerData = row and row[controllerEntity.position.x]
  return controllerData and controllerData["entity-hidden"] and controllerData["entity-hidden"][hiddenEntityIndex]
end

function Traincontroller:getHiddenEntityData(position, direction)
  -- create a list for all hidden entities that needs to be created

  -- STEP 1: Get the orientation offset depending on the orientation
  local signalOffsetX = 0
  local signalOffsetY = 0
  local signalAdditionalOffsetX = 0
  local signalAdditionalOffsetY = 0
  local mapviewOffsetX = 0
  local mapviewOffsetY = 0

  if direction == defines.direction.north then
    signalOffsetX = -0.5
    signalOffsetY = 0.5
    signalAdditionalOffsetX = -3
    --signalAdditionalOffsetY = 0
  elseif direction == defines.direction.east then
    signalOffsetX = -0.5
    signalOffsetY = -0.5
    --signalAdditionalOffsetX = 0
    signalAdditionalOffsetY = -3
  elseif direction == defines.direction.south then
    signalOffsetX = 0.5
    signalOffsetY = -0.5
    signalAdditionalOffsetX = 3
    --signalAdditionalOffsetY = 0
  elseif direction == defines.direction.west then
    signalOffsetX = 0.5
    signalOffsetY = 0.5
    --signalAdditionalOffsetX = 0
    signalAdditionalOffsetY = 3
  end

  -- STEP 2: Return the list with hidden entities.
  -- The old 1.1 mod created two hidden rail signals here. In Factorio 2.0 these
  -- signals can still show/blink on the map, so new controllers only create the
  -- invisible map marker. The builder now uses an explicit rolling-stock check
  -- instead of relying on hidden signal states.
  return {
    [3] = { -- simple entity to show on map
      name      = self:getControllerMapviewEntityName(),
      position  = position, --[[{
        x = position.x + mapviewOffsetX,
        y = position.y + mapviewOffsetY,
      },]]
      direction = direction,
    }
  }
end
