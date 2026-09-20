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

-- options: {deadline = Tick, playerIndex = …} – ohne Frist wartet der Controller unbegrenzt
-- (von Bots gebaut, der Trainbuilder kommt noch). Mit Frist wird das Item danach zurückgegeben.
function Traincontroller:addPendingController(controllerEntity, options)
  if not (controllerEntity and controllerEntity.valid) then return end
  storage.TC_data["pendingControllers"] = storage.TC_data["pendingControllers"] or {}
  local key = controllerEntity.unit_number or
  string.format("%s:%s:%s", controllerEntity.surface.index, controllerEntity.position.x, controllerEntity.position.y)
  storage.TC_data["pendingControllers"][key] = {
    entity = controllerEntity,
    since = game.tick,
    deadline = options and options.deadline or nil,
    playerIndex = options and options.playerIndex or nil,
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
    -- Name einer Kopie behalten, siehe scripts/controller/events.lua
    local keepStationName = self:hasUsefulStationName(controllerEntity)

    controllerEntity.direction = getEntity4WayDirection(controllerEntity)
    self:saveNewStructure(controllerEntity, trainBuilderIndex)
    self:setDefaultMachineTints(trainBuilderIndex)
    if not keepStationName then
      -- siehe scripts/controller/events.lua: der backer_name bleibt englisch (Name des Zughalts)
      controllerEntity.backer_name = "Unused Trainbuilder"
    end
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
    elseif not self:tryActivateController(controllerEntity) then
      -- Controller, die wegen einer Änderung am Trainbuilder warten, haben eine Frist. Passt es
      -- bis dahin nicht, geht das Item zurück und der Zughalt verschwindet.
      if pendingData.deadline and game.tick > pendingData.deadline then
        self:returnControllerItem(controllerEntity, { playerIndex = pendingData.playerIndex })
        pendingControllers[key] = nil
        controllerEntity.destroy { raise_destroy = true }
      end
    end
  end

  self:syncPendingControllerTick()
end
