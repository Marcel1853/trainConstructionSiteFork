---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller: von Bots gebaute Controller, die noch auf ihren Builder warten.

local getEntity4WayDirection = require("scripts.lib.direction")

-- Der Takt liegt in scripts/core/heartbeat.lua; hier wird er nur nachgezogen.
function Traincontroller:activatePendingControllerTick()
  Heartbeat:sync()
end

function Traincontroller:syncPendingControllerTick()
  Heartbeat:sync()
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
    -- siehe scripts/controller/events.lua: der backer_name bleibt englisch (Name des Zughalts)
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
