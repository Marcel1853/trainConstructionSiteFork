---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller: von Bots gebaute Controller, die noch auf ihren Builder warten.

local getEntity4WayDirection = require("scripts.lib.direction")

function Traincontroller:activatePendingControllerTick()
  script.on_nth_tick(120, function(event)
    Traincontroller:processPendingControllers(event)
  end)
end

function Traincontroller:deactivatePendingControllerTick()
  script.on_nth_tick(120, nil)
end

function Traincontroller:syncPendingControllerTick()
  if storage.TC_data and storage.TC_data["pendingControllers"] and next(storage.TC_data["pendingControllers"]) then
    self:activatePendingControllerTick()
  else
    self:deactivatePendingControllerTick()
  end
end

function Traincontroller:addPendingController(controllerEntity)
  if not (controllerEntity and controllerEntity.valid) then return end
  storage.TC_data["pendingControllers"] = storage.TC_data["pendingControllers"] or {}
  local key = controllerEntity.unit_number or
  string.format("%s:%s:%s", controllerEntity.surface.index, controllerEntity.position.x, controllerEntity.position.y)
  storage.TC_data["pendingControllers"][key] = {
    entity = controllerEntity,
    since = game.tick,
  }
  self:activatePendingControllerTick()
end

function Traincontroller:removePendingController(controllerEntity)
  if not (storage.TC_data and storage.TC_data["pendingControllers"] and controllerEntity) then return end
  local key = controllerEntity.unit_number or
  string.format("%s:%s:%s", controllerEntity.surface.index, controllerEntity.position.x, controllerEntity.position.y)
  storage.TC_data["pendingControllers"][key] = nil
  self:syncPendingControllerTick()
end

function Traincontroller:tryActivateController(controllerEntity)
  if not (controllerEntity and controllerEntity.valid and controllerEntity.name == self:getControllerEntityName()) then
    return false
  end
  -- Already active/saved.
  if self:getTrainBuilderIndex(controllerEntity) then
    self:removePendingController(controllerEntity)
    return true
  end

  local validPlacement, trainBuilderIndex = self:checkValidPlacement(controllerEntity, nil, true)
  if validPlacement then
    controllerEntity.direction = getEntity4WayDirection(controllerEntity)
    self:saveNewStructure(controllerEntity, trainBuilderIndex)
    self:setDefaultMachineTints(trainBuilderIndex)
    controllerEntity.backer_name = "Unused Trainbuilder"
    self:removePendingController(controllerEntity)
    return true
  end
  return false
end

function Traincontroller:processPendingControllers(event)
  local pendingControllers = storage.TC_data and storage.TC_data["pendingControllers"]
  if not pendingControllers then return end

  for key, pendingData in pairs(pendingControllers) do
    local controllerEntity = pendingData.entity
    if not (controllerEntity and controllerEntity.valid) then
      pendingControllers[key] = nil
    else
      self:tryActivateController(controllerEntity)
    end
  end

  self:syncPendingControllerTick()
end
