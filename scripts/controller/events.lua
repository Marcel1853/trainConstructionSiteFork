---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller: Ereignisse (bauen, abbauen, drehen, umbenennen, Builder geändert).

local getEntity4WayDirection = require("scripts.lib.direction")

--------------------------------------------------------------------------------
-- Behaviour functions, mostly event handlers
--------------------------------------------------------------------------------
-- When a player builds a new entity
function Traincontroller:onBuildEntity(createdEntity, playerIndex)
  -- The player created a new entity, the player can only place the controller
  -- If he configured the trainbuilder correctly. Otherwise we delete it again
  -- and inform the player what went wrong.
  --
  -- Player experience: The player activated the trainbuilder if its valid.
  if createdEntity.valid and createdEntity.name == self:getControllerEntityName() then
    -- it is the correct entity, now check if its correctly placed
    local validPlacement, trainBuilderIndex = self:checkValidPlacement(createdEntity, playerIndex, not playerIndex)
    if validPlacement then -- It is valid, now we have to add the entity to the list
      -- A copy (blueprint) already carries the name of its depot: keep it, it is the link to
      -- that depot. Check before saving, saving counts this controller as well.
      local keepStationName = self:hasUsefulStationName(createdEntity)

      createdEntity.direction = getEntity4WayDirection(createdEntity)
      self:saveNewStructure(createdEntity, trainBuilderIndex)
      self:setDefaultMachineTints(trainBuilderIndex)

      if not keepStationName then
        -- after structure is saved, we rename it, this will trigger Traincontroller:onRenameEntity as well
        -- Kein Locale-Text: der backer_name ist der Name des Zughalts. Übersetzt hieße derselbe
        -- Halt je nach Sprache anders, und Fahrpläne bestehender Züge würden nicht mehr passen.
        createdEntity.backer_name = "Unused Trainbuilder"
      end
    elseif not playerIndex and createdEntity.valid then
      self:addPendingController(createdEntity)
    end
  end
end

-- When a player/robot removes the building
function Traincontroller:onRemoveEntity(removedEntity)
  -- In some way the building got removed. This results in that the builder is
  -- removed. This also means we have to delete the train that was in this spot.
  --
  -- Player experience: Everything with the trainAssembler gets removed
  if removedEntity.name == self:getControllerEntityName() then
    self:removePendingController(removedEntity)
    -- Removing the controller should only remove automation/control. Do not
    -- destroy a train that has already been assembled on the rails; the player
    -- can remove that train manually if desired.
    self:deleteController(removedEntity)
  end
end

-- When a player rotates an entity
function Traincontroller:onPlayerRotatedEntity(rotatedEntity, playerIndex)
  -- The player rotated the machine entity, we need to make sure the controller
  -- is still valid.
  if rotatedEntity.name == Trainassembly:getMachineEntityName() then
    self:checkValidAftherChanges(rotatedEntity, playerIndex)
  end
end

-- When a player copy pastes a recipe
function Traincontroller:onPlayerChangedSettings(pastedEntity, playerIndex)
  -- The player pasted a recipe in a machine entity, we need to make sure the
  -- controller is still valid.
  if pastedEntity and pastedEntity.valid then
    if pastedEntity.name == Trainassembly:getMachineEntityName() then
      self:checkValidAftherChanges(pastedEntity, playerIndex)
    elseif pastedEntity.name == self:getControllerEntityName() then
      self:setTrainstopControlBehaviour(pastedEntity)
    end
  end
end

-- When a player/script renames an entity
function Traincontroller:onRenameEntity(renamedEntity, oldName)
  if renamedEntity.name == self:getControllerEntityName() and self:getControllerEntity(renamedEntity.surface.index, renamedEntity.position) then
    self:renameBuilding(renamedEntity, oldName)
  end
end

-- when a trainbuilder gets altered (buildings added/deleted buildings)
-- Gibt das Item des Controllers zurück: in den Puffer des abbauenden Spielers/Bots, an den
-- bauenden Spieler, sonst auf den Boden (zum Abholen markiert).
function Traincontroller:returnControllerItem(controllerEntity, receiver)
  local itemStack = { name = self:getControllerItemName(), count = 1 }
  if receiver then
    if receiver.buffer and receiver.buffer.valid then
      if receiver.buffer.insert(itemStack) > 0 then return end
    elseif receiver.playerIndex then
      local player = game.get_player(receiver.playerIndex)
      if player and player.insert(itemStack) > 0 then return end
    end
  end

  local droppedItem = controllerEntity.surface.create_entity {
    name = "item-on-ground",
    stack = itemStack,
    position = controllerEntity.position,
    force = storage.TC_data["trainControllerForces"][controllerEntity.force.name] or controllerEntity.force,
    fast_replace = true,
    spill = false, -- delete excess items (only if fast_replace = true)
  }
  droppedItem.to_be_looted = true
  droppedItem.order_deconstruction(controllerEntity.force)
end

-- receiver: where the controller item should go when the Trainbuilder it controls changes.
-- {buffer = …} is the inventory of the player/robot that mined, {playerIndex = …} the builder.
function Traincontroller:onTrainbuilderAltered(trainBuilderIndex, receiver)
  -- if there is a traincontroller, give its item back (or drop it on the floor)
  local trainController = self:getTrainController(trainBuilderIndex)
  if trainController then
    -- remove the created train
    self:deleteBuildTrain(trainBuilderIndex)

    -- delete from structure
    self:deleteController(trainController)

    -- The Trainbuilder changed, but the controller often still fits: a robot adding the last
    -- wagon of a blueprint, or a wagon mined from a longer Trainbuilder. Put it in the waiting
    -- list instead of removing it; it becomes active again as soon as it fits. Only when it
    -- still does not fit after a while is the item given back (see scripts/controller/pending.lua).
    if trainController.valid then
      local depotForceName = storage.TC_data["trainControllerForces"][trainController.force.name]
      if depotForceName then trainController.force = depotForceName end
      self:addPendingController(trainController, {
        deadline = game.tick + 1800, -- 30 Sekunden
        playerIndex = receiver and receiver.playerIndex or nil,
      })
    end
  end
end
