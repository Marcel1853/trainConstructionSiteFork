---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller.Builder: Zug zusammensetzen, bauen und zum Depot schicken.

local compat = require("compat.factorio_2")
local trainRecipe = require("compat.train_recipe")

--------------------------------------------------------------------------------
-- Getter functions to extract data from the data structure
--------------------------------------------------------------------------------
function Traincontroller.Builder:getBuildTrain(trainBuilderIndex)
  -- this function returns the build train, or nil if none found
  local trainBuilder = Trainassembly:getTrainBuilder(trainBuilderIndex)
  if not trainBuilder then return nil end

  -- STEP 1: Connect all the wagons together
  --         The whole train is already connected, so no need to do this manual

  -- STEP 2: Find one entity that is part of this train
  local machineLocation = trainBuilder[1] -- we know this one is always used (train with length 1)
  if not machineLocation then return nil end

  local trainEntity = Trainassembly:getCreatedEntity(machineLocation.surfaceIndex, machineLocation.position)
  if not (trainEntity and trainEntity.valid) then return nil end

  -- STEP 3: Find the train this trainEntity is part of
  local train = trainEntity.train
  if not (train and train.valid) then return nil end

  -- STEP 4: Before returning this train, make sure this is the whole train! (becose of step 1)
  if not (#train.carriages == #trainBuilder) then
    game.print { "traincontroller-message.trainNotComplete",
      --[[1]] { "item-name.traincontroller", { "item-name.trainassembly" } },
    }
    return nil
  end

  -- STEP 5: Now we can return this train
  return train
end

function Traincontroller.Builder:builderRailIsClear(trainBuilder)
  -- Factorio 2.0 rail signals/hidden signal positions are not always enough to
  -- determine that the previously dispatched train has cleared the build area.
  -- Do one bounded occupancy scan around the whole construction site before
  -- starting the next build. This prevents the next train from spawning into or
  -- coupling with a train that is still leaving, while avoiding per-builder /
  -- per-rolling-stock count queries every update.
  local firstLocation = trainBuilder and trainBuilder[1]
  if not firstLocation then return false end

  local surface = game.get_surface(firstLocation["surfaceIndex"])
  if not surface then return false end

  local minX, minY, maxX, maxY
  for _, builderLocation in pairs(trainBuilder) do
    local position = builderLocation["position"]
    if position then
      minX = minX and math.min(minX, position.x) or position.x
      minY = minY and math.min(minY, position.y) or position.y
      maxX = maxX and math.max(maxX, position.x) or position.x
      maxY = maxY and math.max(maxY, position.y) or position.y
    end
  end

  if not minX then return false end

  local margin = 10
  local nearbyEntities = surface.find_entities_filtered {
    area = {
      { minX - margin, minY - margin },
      { maxX + margin, maxY + margin },
    },
  }
  for _, entity in pairs(nearbyEntities) do
    if Trainassembly:isRollingStock(entity) then
      return false
    end
  end

  return true
end

function Traincontroller.Builder:canBuildNextTrain(trainBuilderIndex, trainBuilderController)
  -- We need to check for each builder if it can place a train there
  local trainBuilder = Trainassembly:getTrainBuilder(trainBuilderIndex)
  if not trainBuilder then return false end
  --game.print("checking if it can build a train with length: "..#trainBuilder)

  -- STEP 1: Check if the construction-site rails are clear. This explicit
  -- rolling-stock check is required in Factorio 2.0 to avoid spawning the next
  -- train while the previous one is still leaving and can couple to it.
  if not self:builderRailIsClear(trainBuilder) then return false end

  -- STEP 2: Check if the train block is empty with the hidden rail signals.
  --         Keep nil/invalid guards for script-created/migrated controllers.
  --         index 2: rail signal on other side of the track
  --                  => checking trainblock where the builder is
  local signalEntity = Traincontroller:getTrainHiddenEntity(trainBuilderController, 2)
  if signalEntity and signalEntity.valid and signalEntity.signal_state ~= defines.signal_state.open then return false end

  --         index 1: rail signal on this side of the track
  --                  => checking trainblock in front of the builder
  signalEntity = Traincontroller:getTrainHiddenEntity(trainBuilderController, 1)
  if signalEntity and signalEntity.valid and signalEntity.signal_state ~= defines.signal_state.open then return false end

  --game.print("signal was green!")

  -- STEP 3: Check if each building can place the train
  for _, builderLocation in pairs(trainBuilder) do
    local machineEntity = Trainassembly:getMachineEntity(builderLocation["surfaceIndex"], builderLocation["position"])
    if machineEntity and machineEntity.valid then
      local machineRecipe = machineEntity.get_recipe()
      if not machineRecipe then
        Traincontroller:checkValidAftherChanges(machineEntity, nil)
        return false
      end
      local buildEntityName = trainRecipe.parse_name(machineRecipe.name)
      if not buildEntityName then return false end

      if not game.surfaces[builderLocation["surfaceIndex"]].can_place_entity {
            name             = buildEntityName,
            position         = builderLocation["position"],
            direction        = Trainassembly:getMachineDirection(machineEntity),
            force            = machineEntity.force,
            build_check_type = defines.build_check_type.manual
          } then
        -- If we cannot place it, we can't build a train yet
        return false
      end
    else -- This should never have an invalid machineEntity...
      return false
    end
  end

  return true -- if we can build everywhere, we return true eventualy
end

function Traincontroller.Builder:buildNextTrain(trainBuilderIndex)
  -- We know we can build a train, so we start building it now
  -- We need to check for each builder if it can place a train there
  local trainBuilder = Trainassembly:getTrainBuilder(trainBuilderIndex)
  if not trainBuilder then return false end

  local finishTrainBuild = true -- track if the train is fully build
  for _, builderLocation in pairs(trainBuilder) do
    -- iterate over each building
    local machineEntity = Trainassembly:getMachineEntity(builderLocation["surfaceIndex"], builderLocation["position"])
    if machineEntity and machineEntity.valid then
      -- get the building entity out of the name
      local machineRecipe = machineEntity.get_recipe()
      if not machineRecipe then
        Traincontroller:checkValidAftherChanges(machineEntity, nil)
        return false
      end
      local buildEntityName = trainRecipe.parse_name(machineRecipe.name)
      if not buildEntityName then return false end

      -- Capture Space Age item quality while the train-part ingredient is still
      -- in the input inventory. The recipe output itself is a fluid and cannot
      -- carry quality.
      local pendingQuality = Trainassembly:capturePendingQuality(machineEntity, machineRecipe)

      -- get the maybe already existing entity
      local createdEntity = Trainassembly:getCreatedEntity(builderLocation["surfaceIndex"], builderLocation["position"])
      if createdEntity and (not createdEntity.valid) then
        createdEntity = nil -- if not valid
      end

      if not createdEntity then
        -- there was no entity, or the already existing entity got removed above this code

        -- first we need to check if the recipe has made a result
        -- Factorio 2.1: fluidbox property removed; use get_fluid(index) instead
        local machineOutput = machineEntity.get_fluid(1)
        if machineOutput and machineOutput.amount >= 1 then
          local machineDirection = Trainassembly:getMachineDirection(machineEntity)

          -- the recipe made a result, now we can place it
          createdEntity = game.surfaces[builderLocation["surfaceIndex"]].create_entity {
            name               = buildEntityName,
            position           = builderLocation["position"],
            direction          = machineDirection,
            quality            = pendingQuality,
            force              = machineEntity.force,
            snap_to_train_stop = false,
          }
          if createdEntity and (not FLib.utils.table.areEqual(createdEntity.position, builderLocation["position"])) then
            -- it snapped to a train stop probably, so let us build it in reverse first
            createdEntity.destroy()
            createdEntity = game.surfaces[builderLocation["surfaceIndex"]].create_entity {
              name               = buildEntityName,
              position           = builderLocation["position"],
              direction          = FLib.utils.directions.oposite(machineDirection),
              quality            = pendingQuality,
              force              = machineEntity.force,
              snap_to_train_stop = false,
            }
            -- and afther creating it in reverse, we rotate it back
            if not (createdEntity and createdEntity.rotate()) then
              if createdEntity then
                createdEntity.destroy() -- for some reason it still didn't work
                createdEntity = nil
              end
            end
          end

          if createdEntity then
            -- now the entity is created, start saving this entity
            Trainassembly:setCreatedEntity(builderLocation["surfaceIndex"], builderLocation["position"], createdEntity)

            -- if this is a locomotive, we have to do some more stuff
            local _, buildEntityType = trainRecipe.parse_name(machineRecipe.name)
            if buildEntityType == "locomotive" then
              -- insert fuel if recipe had fuel
              for _, ingredient in pairs(machineRecipe.ingredients) do
                if ingredient.name == "trainassembly-recipefuel" then
                  createdEntity.get_fuel_inventory().insert {
                    name  = "trainassembly-trainfuel",
                    count = ingredient.amount,
                  }
                elseif Trainassembly:isFuelItem(ingredient.name) then
                  createdEntity.get_fuel_inventory().insert {
                    name  = ingredient.name,
                    count = ingredient.amount,
                  }
                end
              end

              -- give it some color
              local createdEntityColor = Trainassembly:getMachineTint(machineEntity)
              createdEntity.color = {
                r = createdEntityColor.r,
                g = createdEntityColor.g,
                b = createdEntityColor.b,
                a = createdEntity.color and createdEntity.color.a or 127 / 255, -- hardcoded for vanilla trains
              }
            end

            -- Quality marker consumed; the next craft will capture a new quality.
            Trainassembly:setPendingQuality(machineEntity, "normal")

            -- now substract one result from the assembler
            -- Factorio 2.1: remove_fluid(index, amount) removes from fluidbox at index
            machineEntity.remove_fluid(1, 1)

            -- now that we finised this one, we can raise the event for other mods
            script.raise_event(defines.events.script_raised_built, {
              entity = createdEntity
            })
          else
            -- if the entity could not be created, the build is not finished yet
            finishTrainBuild = false
          end
        else
          -- if the recipe did not create a result yet, the build is not finished yet
          finishTrainBuild = false
        end
        finishTrainBuild = false -- invalid result fluid, should never happen
      end
    end
  end

  return finishTrainBuild
end

function Traincontroller.Builder:depotIsRequestingTrain(controllerEntity)
  local controllerName         = controllerEntity.backer_name
  local controllerSurfaceIndex = controllerEntity.surface.index
  local depotForceName         = Traincontroller:getDepotForceName(controllerEntity.force.name)

  local depotRequestCount      = Traindepot:getDepotRequestCount(depotForceName, controllerSurfaceIndex, controllerName)
  local depotTrainCount        = Traindepot:getNumberOfTrainsPathingToDepot(controllerSurfaceIndex, controllerName)

  return depotTrainCount < depotRequestCount
end

function Traincontroller.Builder:assembleNextTrain(trainBuilderIndex, depotName)
  -- The whole train is assembled, so now we can send it away

  -- STEP 1: Get the train that is created (not the individual carriages)
  local train = self:getBuildTrain(trainBuilderIndex)
  if not train then return false end

  -- STEP 2: Set the schedule for this train
  -- STEP 2a:Create the schedule
  local trainSchedule = { -- the train schedule
    -- https://lua-api.factorio.com/latest/Concepts.html#TrainSchedule
    current = 1,          -- record the train is traveling too
    records = {
      -- the train schedule recods
      -- https://lua-api.factorio.com/latest/Concepts.html#TrainScheduleRecord

      -- First record: depot stop --
      {
        station         = depotName, -- name of the depot station
        wait_conditions = {
          -- wait conditions at this station
          -- https://lua-api.factorio.com/latest/Concepts.html#WaitCondition

          -- first wait condition
          {
            type         = "circuit",
            compare_type = "and", -- tells how this condition is to be compared with the preceding conditions
            ticks        = nil,   -- number of ticks to wait or of inactivity
            condition    = {
              -- condition when type is "item_count" or "circuit"
              -- https://lua-api.factorio.com/latest/Concepts.html#CircuitCondition
              comparator    = "<",
              first_signal  = nil, -- blank, no condition set
              second_signal = nil, -- if not set, it will compare to constant
              constant      = nil, -- if not set, will default to 0
            },
          },                       -- end of first wait condition

        },
      }, -- end of first record

    },
  } -- end of trainSchedule

  -- STEP 2b:Add the schedule to the train
  compat.set_train_schedule(train, trainSchedule)

  -- STEP 3: Send the train away
  -- STEP 3a:Set it in automatic mode
  train.manual_mode = false

  -- STEP 3b:Check if the train has a path, if it has, it will drive away
  if not train.recalculate_path() then
    return false -- no pathing
  end

  -- STEP 4: Clear the train buildings to start making a new one
  for _, builderLocation in pairs(Trainassembly:getTrainBuilder(trainBuilderIndex) or {}) do
    Trainassembly:setCreatedEntity(builderLocation["surfaceIndex"], builderLocation["position"], nil)
  end

  return true
end
