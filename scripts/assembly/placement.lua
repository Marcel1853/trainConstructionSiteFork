---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Trainassembly: Platzieren prüfen (Wagen und von Hand gesetzte Züge).

local getEntity4WayDirection = require("scripts.lib.direction")

function Trainassembly:checkValidPlacement(createdEntity, playerIndex)
  -- Checks the correct placement of the trainassembler, if not validly placed,
  -- it will inform the player with the corresponding message and return the
  -- trainassembler to the player. If no player is found, it will drop the
  -- trainassembler on the ground where the trainassembler was placed.
  local entityPosition = createdEntity.position

  local notValid = function(localisedMessage)
    -- Try return the item to the player (or drop it)
    if playerIndex then -- return if possible
      local player = game.players[playerIndex]
      --player.print(localisedMessage)
      player.create_local_flying_text{
        text = localisedMessage,
        position = entityPosition,
      }
      player.insert{
        name = self:getItemName(),
        count = 1,
      }
    else -- drop it otherwise
      local droppedItem = createdEntity.surface.create_entity{
        name = "item-on-ground",
        stack = {
          name = self:getItemName(),
          count = 1,
        },
        position = createdEntity.position,
        force = createdEntity.force,
        fast_replace = true,
        spill = false, -- delete excess items (only if fast_replace = true)
      }
      droppedItem.to_be_looted = true
      droppedItem.order_deconstruction(createdEntity.force)
    end

    -- Destroy the placed item
    createdEntity.destroy()
    return false
  end

  local entitySurface = createdEntity.surface
  local entityDirection = getEntity4WayDirection(createdEntity)
  local entityOpositeDirection = FLib.utils.directions.oposite(entityDirection)

  -- STEP 1: check the rails underneath. The 1.1 version relied on the
  -- temporary locomotive prototype being rail-only-placeable. In Factorio 2.0
  -- this prototype can be placed too freely after the prototype migration, so
  -- the script must reject placements that are not on a valid straight rail.
  local foundValidRail = false
  for _,railEntity in pairs(entitySurface.find_entities_filtered{
    --name = "straight-rail",
    type = "straight-rail",
    area = {
      {entityPosition.x - 3.1, entityPosition.y - 3.1},
      {entityPosition.x + 3.1, entityPosition.y + 3.1},
    },
  }) do
    local railDirection = railEntity.direction
    if railDirection == entityDirection or railDirection == entityOpositeDirection then
      -- STEP 1a: If the rail is in the correct direction, there could still be
      --          a rail that is parallel to the one its standing on.
      if railDirection == defines.direction.north or railDirection == defines.direction.south then
        -- check the x position
        if railEntity.position.x ~= entityPosition.x then
          return notValid{"trainassembler-message.noMultipleRailways", {"item-name.trainassembly"}}
        end
      else
        -- check the y position
        if railEntity.position.y ~= entityPosition.y then
          return notValid{"trainassembler-message.noMultipleRailways", {"item-name.trainassembly"}}
        end
      end
      foundValidRail = true

    else
      -- STEP 1b: If there is a rail oriented wrong, check whats wrong to
      --          display a suitable message. The message depends on what
      --          direction the rail is facing (diagonal or perpendicular)
      local localisedMessage = {
        -- crossings (vertical or horizontal)
        [defines.direction.north    ] = {"trainassembler-message.noCrossingPlacement", {"item-name.trainassembly"}},
        [defines.direction.east     ] = {"trainassembler-message.noCrossingPlacement", {"item-name.trainassembly"}},
        [defines.direction.south    ] = {"trainassembler-message.noCrossingPlacement", {"item-name.trainassembly"}},
        [defines.direction.west     ] = {"trainassembler-message.noCrossingPlacement", {"item-name.trainassembly"}},
        -- diagonal
        [defines.direction.northeast] = {"trainassembler-message.noDiagonalPlacement", {"item-name.trainassembly"}},
        [defines.direction.southeast] = {"trainassembler-message.noDiagonalPlacement", {"item-name.trainassembly"}},
        [defines.direction.southwest] = {"trainassembler-message.noDiagonalPlacement", {"item-name.trainassembly"}},
        [defines.direction.northwest] = {"trainassembler-message.noDiagonalPlacement", {"item-name.trainassembly"}},
      }
      return notValid(localisedMessage[railDirection] or {"trainassembler-message.noRailPlacement", {"item-name.trainassembly"}})
    end
  end

  if not foundValidRail then
    return notValid{"trainassembler-message.noRailPlacement", {"item-name.trainassembly"}}
  end

  -- STEP 2: Do not allow stacking/overlapping trainassemblers at the same rail
  -- segment. This also protects against mass-placement crashes when the hidden
  -- temporary entity does not collide as expected.
  for _, existingTrainassembler in pairs(entitySurface.find_entities_filtered{
    name = self:getMachineEntityName(),
    type = "assembling-machine",
    area = {
      {entityPosition.x - 2.95, entityPosition.y - 2.95},
      {entityPosition.x + 2.95, entityPosition.y + 2.95},
    },
  }) do
    if existingTrainassembler ~= createdEntity then
      return notValid{"trainassembler-message.noMultipleTrainassemblers", {"item-name.trainassembly"}}
    end
  end

  -- STEP 3: If all previous checks succeeded, it means it is validly placed.
  return true
end





function Trainassembly:allowManualTrainPlacement()
  return settings.global["trainController-manual-placing-trains"] and
         settings.global["trainController-manual-placing-trains"].value or false
end



function Trainassembly:isManagedCreatedTrainEntity(trainEntity)
  if not (trainEntity and trainEntity.valid) then return false end
  local createdEntity = self:getCreatedEntity(trainEntity.surface.index, trainEntity.position)
  return createdEntity and createdEntity.valid and createdEntity == trainEntity
end



function Trainassembly:getRollingStockItemName(trainEntity)
  if trainEntity and trainEntity.valid and trainEntity.prototype and trainEntity.prototype.mineable_properties then
    local products = trainEntity.prototype.mineable_properties.products
    if products and products[1] and products[1].name then
      return products[1].name
    end
  end
  return trainEntity and trainEntity.name or "locomotive"
end



function Trainassembly:onInvalidManualRollingStockPlacement(trainEntity, playerIndex)
  local itemName = self:getRollingStockItemName(trainEntity)
  local itemQuality = self:getQualityName(trainEntity.quality)
  local surface = trainEntity.surface
  local position = trainEntity.position
  local force = trainEntity.force

  if playerIndex then
    local player = game.get_player(playerIndex)
    if player then
      player.insert{name = itemName, count = 1, quality = itemQuality}
      player.create_local_flying_text{
        text = {"trainassembler-message.noManualTrainPlacement", {"item-name.trainassembly"}},
        position = position,
      }
    end
  else
    surface.create_entity{
      name = "item-on-ground",
      stack = {name = itemName, count = 1, quality = itemQuality},
      position = position,
      force = force,
      fast_replace = true,
      spill = false,
    }
  end

  trainEntity.destroy{raise_destroy = false}
end
