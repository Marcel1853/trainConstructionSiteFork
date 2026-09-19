---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller: Platzieren prüfen und nach Änderungen am Builder erneut prüfen.

local trainRecipe = require("compat.train_recipe")
local getEntity4WayDirection = require("scripts.lib.direction")

function Traincontroller:checkValidAftherChanges(alteredEntity, playerIndex)
  -- A valid trainbuilder got altered. This happens when a building gets rotated
  -- or when a recipe got changed. We have to check if all recipes are set and
  -- if the builder has a validly placed locomotive still.

  if alteredEntity and alteredEntity.valid and alteredEntity.name == Trainassembly:getMachineEntityName() then
    local trainBuilderIndex = Trainassembly:getTrainBuilderIndex(alteredEntity)
    local trainController = self:getTrainController(trainBuilderIndex)
    if trainController then
      local notValid = function(localisedMessage)
        -- Try return the item to the player (or drop it)
        if playerIndex then -- return if possible
          local player = game.players[playerIndex]
          player.print(localisedMessage)
          player.insert {
            name = self:getControllerItemName(),
            count = 1,
          }
        else -- drop it otherwise
          local droppedItem = trainController.surface.create_entity {
            name = "item-on-ground",
            stack = {
              name = self:getControllerItemName(),
              count = 1,
            },
            position = trainController.position,
            force = storage.TC_data["trainControllerForces"][trainController.force.name] or trainController.force,
            fast_replace = true,
            spill = false, -- delete excess items (only if fast_replace = true)
          }
          droppedItem.to_be_looted = true
          droppedItem.order_deconstruction(trainController.force)
        end

        -- remove the created train
        self:deleteBuildTrain(trainBuilderIndex)

        -- Delete it from the data structure
        self:deleteController(trainController)

        -- Destroy the placed item
        trainController.destroy { raise_destroy = true }
        return false
      end

      -- We know it is already validly placed, so we can check the trainbuilder
      -- and only have to check if it still has a locomotive facing the correct
      -- direction
      local hasValidLocomotive = false
      local hasAllRecipesSet = true
      for _, builderLocation in pairs(Trainassembly:getTrainBuilder(trainBuilderIndex)) do
        local machineEntity = Trainassembly:getMachineEntity(builderLocation["surfaceIndex"], builderLocation
        ["position"])
        if machineEntity and machineEntity.valid and machineEntity.direction == trainController.direction then
          -- Step 1: Check if the recipe is set for each building, if not, this
          --         controller has become invalid, we don't have to look further
          local machineRecipe = machineEntity.get_recipe()
          if not machineRecipe then
            return notValid { "traincontroller-message.noBuilderRecipeFound", { "item-name.trainassembly" } }
          end

          -- Step 2: If this controller doesn't have a valid locomotive yet, we
          --         still have to check if this one might be a valid locomotive
          if not hasValidLocomotive then
            local _, builderType = trainRecipe.parse_name(machineRecipe.name)
            if builderType == "locomotive" then
              hasValidLocomotive = true
            end
          end
        end
      end

      if not hasValidLocomotive then
        return notValid { "traincontroller-message.noValidLocomotiveFound",
          --[[1]] { "item-name.trainassembly" },
          --[[2]] "__ENTITY__locomotive__",
          --[[3]] { "item-name.traincontroller", { "item-name.trainassembly" } },
        }
      end

      self.Gui:updateOpenedGuis(trainController)
      return true
    end

    return false -- return false if no traincontroller found
  end

  return true -- return true if alteredEntity is not valid
end

function Traincontroller:checkValidPlacement(createdEntity, playerIndex, deferInvalid)
  -- Checks the correct placement of the traincontroller, if not validly placed,
  -- it will inform the player with the corresponding message and return the
  -- traincontroller to the player. If no player is found, it will drop the
  -- traincontroller on the ground where the traincontroller was placed.

  -- this is the actual force of the player, not the friendly force
  local createdEntityForceName = storage.TC_data["trainControllerForces"][createdEntity.force.name] or
  createdEntity.force.name
  local entityPosition = createdEntity.position

  local notValid = function(localisedMessage)
    -- Robot/blueprint builds may happen before the builder/depot from the same
    -- blueprint exists. Keep the controller around and retry later instead of
    -- deleting it immediately.
    if deferInvalid then
      return false, -1
    end

    -- Try return the item to the player (or drop it)
    if playerIndex then -- return if possible
      local player = game.players[playerIndex]
      --player.print(localisedMessage)
      player.create_local_flying_text {
        text = localisedMessage,
        position = entityPosition,
      }
      player.insert {
        name = self:getControllerItemName(),
        count = 1,
      }
    else -- drop it otherwise
      local droppedItem = createdEntity.surface.create_entity {
        name = "item-on-ground",
        stack = {
          name = self:getControllerItemName(),
          count = 1,
        },
        position = createdEntity.position,
        force = createdEntityForceName,
        fast_replace = true,
        spill = false, -- delete excess items (only if fast_replace = true)
      }
      droppedItem.to_be_looted = true
      droppedItem.order_deconstruction(createdEntity.force)
    end

    -- Destroy the placed item
    createdEntity.destroy()
    return false, -1
  end

  -- STEP 1: Check if at least one train depot has been placed, if not, the
  --         trainbuilder can't let trains drive off.
  if not Traindepot:hasDepotEntities(createdEntityForceName, createdEntity.surface.index) then
    return notValid { "traincontroller-message.noTraindepotFound",
      --[[1]] { "item-name.traincontroller", { "item-name.trainassembly" } },
      --[[2]] { "item-name.traindepot" },
    }
  end

  -- STEP 2: Look for a trainassembler, if there is no trainassembler found,
  --         the controller is placed wrong
  local entityDirection = getEntity4WayDirection(createdEntity) -- direction to look for a trainbuilder
  local entitySearchDirection = { x = 0, y = 0 }

  if entityDirection == defines.direction.west then
    entitySearchDirection.x = 1
  elseif entityDirection == defines.direction.east then
    entitySearchDirection.x = -1
  elseif entityDirection == defines.direction.north then
    entitySearchDirection.y = 1
  elseif entityDirection == defines.direction.south then
    entitySearchDirection.y = -1
  end
  local entitySurface = createdEntity.surface
  local entitySurfaceIndex = entitySurface.index

  local builderEntity
  local bestBuilderScore
  for _, candidate in pairs(entitySurface.find_entities_filtered {
    name  = Trainassembly:getMachineEntityName(),
    force = createdEntityForceName,
    area  = {
      { entityPosition.x - 10, entityPosition.y - 10 },
      { entityPosition.x + 10, entityPosition.y + 10 },
    },
  }) do
    if candidate and candidate.valid then
      local dx = candidate.position.x - entityPosition.x
      local dy = candidate.position.y - entityPosition.y
      local forward = dx * entitySearchDirection.x + dy * entitySearchDirection.y
      local sideward = math.abs(dx * entitySearchDirection.y - dy * entitySearchDirection.x)

      -- Old 1.1 positions put the first builder roughly 4.5 tiles behind the
      -- controller. Factorio 2.0 rail/stop placement can shift this a little,
      -- so accept a wider corridor while still requiring the builder to be on
      -- the side the controller controls.
      if forward >= 1.5 and forward <= 8.5 and sideward <= 4.5 then
        local score = math.abs(forward - 4.5) + sideward
        if not bestBuilderScore or score < bestBuilderScore then
          builderEntity = candidate
          bestBuilderScore = score
        end
      end
    end
  end

  if not (builderEntity and builderEntity.valid) then
    -- Fallback: Factorio 2.0 train stop placement/rail snapping can differ from
    -- 1.1 enough that the old rectangle misses the builder. Pick the nearest
    -- valid train assembly in a sane radius so the controller still links to the
    -- builder the player placed it next to.
    local bestDistance
    for _, candidate in pairs(entitySurface.find_entities_filtered {
      name  = Trainassembly:getMachineEntityName(),
      force = createdEntityForceName,
      area  = {
        { entityPosition.x - 16, entityPosition.y - 16 },
        { entityPosition.x + 16, entityPosition.y + 16 },
      },
    }) do
      local candidateBuilderIndex = Trainassembly:getTrainBuilderIndex(candidate)
      if candidate and candidate.valid and candidateBuilderIndex then
        local dx = candidate.position.x - entityPosition.x
        local dy = candidate.position.y - entityPosition.y
        local distance = dx * dx + dy * dy
        if not bestDistance or distance < bestDistance then
          builderEntity = candidate
          bestDistance = distance
        end
      end
    end
  end

  if not (builderEntity and builderEntity.valid) then
    return notValid { "traincontroller-message.noTrainbuilderFound", { "item-name.trainassembly" } }
  end

  -- STEP 3: Find the trainbuilder that this trainassembler is part of
  local builderIndex = Trainassembly:getTrainBuilderIndex(builderEntity)
  -- STEP 3a: If there is no trainbuilder found, the controller is placed wrong.
  if not builderIndex then
    return notValid { "traincontroller-message.invalidTrainbuilderFound", { "item-name.trainassembly" } }
  end
  -- STEP 3b: If there is one, we need to make sure it isn't controlled yet.
  if self:getTrainController(builderIndex) then
    return notValid { "traincontroller-message.isAlreadyControlled",
      --[[1]] { "item-name.trainassembly" },
      --[[2]] { "item-name.traincontroller", { "item-name.trainassembly" } },
    }
  end

  -- STEP 4: Make sure the trainbuilder has all recipes set, and at least
  --         one of the recipes must be a locomotive that is facing it the
  --         direction the train is supposed to leave.
  local hasValidLocomotive = false
  for _, builderLocation in pairs(Trainassembly:getTrainBuilder(builderIndex)) do
    local machineEntity = Trainassembly:getMachineEntity(builderLocation["surfaceIndex"], builderLocation["position"])
    if machineEntity and machineEntity.valid then
      -- check the recipe of each machineEntity
      local machineRecipe = machineEntity.get_recipe()
      if not machineRecipe then
        return notValid { "traincontroller-message.noBuilderRecipeFound", { "item-name.trainassembly" } }
      end

      if (not hasValidLocomotive) and (machineEntity.direction == entityDirection) then
        -- check the direction of the locomotive
        local _, builderType = trainRecipe.parse_name(machineRecipe.name)
        if builderType == "locomotive" then
          hasValidLocomotive = true
        end
      end
    else
      return notValid("ERROR: Invalid building! Report this please.")
    end
  end

  if not hasValidLocomotive then
    return notValid { "traincontroller-message.noValidLocomotiveFound",
      --[[1]] { "item-name.trainassembly" },
      --[[2]] "__ENTITY__locomotive__",
      --[[3]] { "item-name.traincontroller", { "item-name.trainassembly" } },
    }
  end

  -- STEP 5: If all previous checks succeeded, it means it is validly placed.
  return true, builderIndex
end
