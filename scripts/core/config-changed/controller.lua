---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Datenstand von Traincontroller (storage.TC_data) hochziehen.
-- Teil von on_configuration_changed, siehe init.lua.

return function()
  --------------------------------------------------
  -- Traincontroller script                       --
  --------------------------------------------------
  if storage.TC_data.version == 1 then
    log("Updating Traincontroller from version 1 to version 2.")
    if FLib.utils.table.isEmpty(storage.TC_data["trainControllers"]) and storage.TC_data["nextTrainControllerIterate"] then
      storage.TC_data["nextTrainControllerIterate"] = nil
      Traincontroller.Builder:deactivateOnTick()
    end
    storage.TC_data.version = 2
  end

  if storage.TC_data.version == 2 then
    log("Updating Traincontroller from version 2 to version 3.")
    for surfaceIndex, surfaceData in pairs(storage.TC_data["trainControllers"] or {}) do
      for controllerPositionY, controllerPositionData in pairs(surfaceData) do
        for controllerPositionX, controllerData in pairs(controllerPositionData) do
          for _, hiddenEntity in pairs(controllerData["entity-hidden"]) do
            if hiddenEntity.valid then
              hiddenEntity.destroy()
            end
          end
          controllerData["entity-hidden"] = {}
          local controllerEntity = controllerData["entity"]
          for hiddenEntityIndex, hiddenEntityData in pairs(Traincontroller:getHiddenEntityData(controllerEntity.position, controllerEntity.direction)) do
            controllerData["entity-hidden"][hiddenEntityIndex] = controllerEntity.surface.create_entity{
              name      = hiddenEntityData.name,
              position  = hiddenEntityData.position,
              direction = hiddenEntityData.direction,
              force     = Traincontroller:getDepotForceName(controllerEntity.force.name)
            }
          end
          if storage.TA_data["trainBuilders"][controllerData.trainBuilderIndex] then
          else
            local controllerEntity = controllerData.entity
            if controllerEntity and controllerEntity.valid then
              local createdEntityForceName = storage.TC_data["trainControllerForces"][controllerEntity.force.name] or controllerEntity.force.name
              local entityDirection = controllerEntity.direction
              local entitySearchDirection = {
                x = (entityDirection == defines.direction.west  and 1 or 0) + (entityDirection == defines.direction.east  and -1 or 0),
                y = (entityDirection == defines.direction.north and 1 or 0) + (entityDirection == defines.direction.south and -1 or 0),
              }
              local entityPosition = controllerEntity.position
              local newBuilderIndex = Trainassembly:getTrainBuilderIndex(controllerData.entity.surface.find_entities_filtered{
                name     = Trainassembly:getMachineEntityName(),
                force    = createdEntityForceName,
                area     = {
                  { entityPosition.x + 3.5*entitySearchDirection.x - 1.5*entitySearchDirection.y , entityPosition.y + 3.5*entitySearchDirection.y + 1.5*entitySearchDirection.x },
                  { entityPosition.x + 5.5*entitySearchDirection.x - 2.5*entitySearchDirection.y , entityPosition.y + 5.5*entitySearchDirection.y + 2.5*entitySearchDirection.x },
                },
                limit    = 1,
              }[1])
              if newBuilderIndex == controllerData.trainBuilderIndex then
                Traincontroller:onTrainbuilderAltered(controllerData.trainBuilderIndex)
              else
                controllerData.trainBuilderIndex = newBuilderIndex
              end
            end
          end
          local builderStates = Traincontroller.Builder:initGlobalData()["builderStates"]
          if controllerData["controllerStatus"] == builderStates["idle"] or
             controllerData["controllerStatus"] == builderStates["dispatch"] then
            if Traincontroller.Builder:getBuildTrain(controllerData.trainBuilderIndex) then
            else
              controllerData["controllerStatus"] = builderStates["building"]
            end
          end
        end
      end
    end
    storage.TC_data.version = 3
  end

  if storage.TC_data.version == 3 then
    log("Updating Traincontroller from version 3 to version 4.")
    storage.TC_data["pendingControllers"] = storage.TC_data["pendingControllers"] or {}
    for _, surface in pairs(game.surfaces) do
      for _, signal in pairs(surface.find_entities_filtered{name = Traincontroller:getControllerSignalEntityName()}) do
        if signal and signal.valid then signal.destroy() end
      end
    end
    for _, surfaceData in pairs(storage.TC_data["trainControllers"] or {}) do
      for _, positionYData in pairs(surfaceData) do
        for _, controllerData in pairs(positionYData) do
          for hiddenEntityIndex, hiddenEntity in pairs(controllerData["entity-hidden"] or {}) do
            if hiddenEntity and hiddenEntity.valid and hiddenEntity.name == Traincontroller:getControllerSignalEntityName() then
              hiddenEntity.destroy()
              controllerData["entity-hidden"][hiddenEntityIndex] = nil
            end
          end
        end
      end
    end
    storage.TC_data.version = 4
    Traincontroller:syncPendingControllerTick()
  end


end
