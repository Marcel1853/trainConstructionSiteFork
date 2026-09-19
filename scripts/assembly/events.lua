---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Trainassembly: Ereignisse (bauen, abbauen, drehen, Einstellungen einfügen).

local compat = require("compat.factorio_2")
local getEntity4WayDirection = require("scripts.lib.direction")

--------------------------------------------------------------------------------
-- Behaviour functions, mostly event handlers
--------------------------------------------------------------------------------
-- When a player builds a new entity
function Trainassembly:onBuildEntity(createdEntity, playerIndex)
  -- The player created a new entity, the player can only place the placeable item.
  -- So we have to check if the player placed this entity, if so, we remove it.
  -- We manualy have to build a machine entity on the same spot.
  --
  -- Player experience: The player thinks he builded an assembling machine on top of rails.
  if createdEntity.name == self:getPlaceableEntityName() or
     createdEntity.name == self:getMachineEntityName() then
    -- We know the createdEntity is the placeable entity, meaning the player wants
    -- to build a trainassembly on this spot

    -- STEP 1: check if the assembling machine is validly placed.
    if self:checkValidPlacement(createdEntity, playerIndex) then
      local entitySurface = createdEntity.surface
      local entityPosition = createdEntity.position
      local entityForce = createdEntity.force
      local entityDirection = getEntity4WayDirection(createdEntity)
      local createdEntityName = createdEntity.name

      -- STEP 2: place/use the assembling machine on the same spot. The item
      -- places a short-lived preview entity with the correct visuals; replace it
      -- with the tracked trainassembly-machine after validation. If another mod
      -- or old save creates the machine directly, keep that machine.
      local machineEntity
      if createdEntityName == self:getMachineEntityName() then
        machineEntity = createdEntity
        machineEntity.direction = entityDirection
      else
        createdEntity.destroy()
        machineEntity = entitySurface.create_entity({
          name      = self:getMachineEntityName(),
          position  = entityPosition,
          direction = entityDirection,
          force     = entityForce,
        })
      end

      -- STEP 3: make the rails underneath unminable
      for _,railEntity in pairs(entitySurface.find_entities_filtered{
        name  = "straight-rail",
        type  = "straight-rail",
        --force = entityForce,
        area  = {
          {entityPosition.x - 3.1, entityPosition.y - 3.1},
          {entityPosition.x + 3.1, entityPosition.y + 3.1},
        },
      }) do
        railEntity.destructible = false -- entity can't be damaged
        railEntity.minable_flag      = true  -- keep blueprintable; rail removal is handled at runtime
      end

      local machineRenderID = {}
      for animationLayer,renderLayer in pairs{
        ["base"] = "lower-object",
        -- @Bilka said:
        -- "item-in-inserter-hand" = 134
        -- "higher-object-above"   = 132
        ["overlay"] = "item-in-inserter-hand"
      } do
        machineRenderID[animationLayer] = rendering.draw_animation{
          animation = machineEntity.name .. "-" .. FLib.utils.directions.toString(machineEntity.direction) .. "-" .. animationLayer,
          render_layer = renderLayer,
          target = machineEntity,
          surface = machineEntity.surface,
        }
      end

      -- STEP 4: Save the newly made trainassembly to our data structure so we can keep track of it
      self:saveNewStructure(machineEntity, machineRenderID)
      if Traincontroller and Traincontroller.processPendingControllers then
        Traincontroller:processPendingControllers()
      end
    end

  elseif createdEntity.name == "straight-rail" then
    local machineOnRail = createdEntity.surface.find_entities_filtered{
      name      = self:getMachineEntityName(),
      type      = "assembling-machine",
      area      = {{x = createdEntity.position.x - .5, y = createdEntity.position.y - .5},
                   {x = createdEntity.position.x + .5, y = createdEntity.position.y + .5},},
      limit     = 1,
    }[1]
    if machineOnRail then
      -- Blueprint/robot builds can place rails after the Trainbuilder. Keep the
      -- rail and protect it instead of destroying it; otherwise blueprints miss
      -- the short rail pieces between/under builders.
      createdEntity.destructible = false
      createdEntity.minable_flag = true -- keep rails blueprintable
      if Traincontroller and Traincontroller.processPendingControllers then
        Traincontroller:processPendingControllers()
      end
    end

  elseif self:isRollingStock(createdEntity) then
    if (not self:allowManualTrainPlacement()) and (not self:isManagedCreatedTrainEntity(createdEntity)) then
      self:onInvalidManualRollingStockPlacement(createdEntity, playerIndex)
      return
    end

    if script.active_mods["MultipleUnitTrainControl"] and string.sub(createdEntity.name, -3) == "-mu" and
      createdEntity.surface.count_entities_filtered{
        name     = self:getMachineEntityName(),
        position = createdEntity.position,
        force    = createdEntity.force,
        limit    = 1,
      } > 0 then
      self:setCreatedEntity(createdEntity.surface.index, createdEntity.position, createdEntity)
    end
  end
end

-- Trainbuilder machines that stand on this (straight) rail piece
function Trainassembly:getMachinesOnRail(railEntity)
  local railPosition = railEntity.position
  local railVertical = railEntity.direction == defines.direction.north or railEntity.direction == defines.direction.south
  local railHorizontal = railEntity.direction == defines.direction.east or railEntity.direction == defines.direction.west
  local machines = {}
  if not (railVertical or railHorizontal) then return machines end -- diagonal rail
  for _, machineEntity in pairs(railEntity.surface.find_entities_filtered{
    name = self:getMachineEntityName(),
    type = "assembling-machine",
    area = {{railPosition.x - 4, railPosition.y - 4}, {railPosition.x + 4, railPosition.y + 4}},
  }) do
    local machinePosition = machineEntity.position
    local machineVertical = machineEntity.direction == defines.direction.north or machineEntity.direction == defines.direction.south
    -- the rail must lie on the machine's track: same axis, less than one tile sideways
    if machineVertical == railVertical then
      local sideways = railVertical and math.abs(machinePosition.x - railPosition.x) or math.abs(machinePosition.y - railPosition.y)
      if sideways < 1 then
        machines[#machines + 1] = machineEntity
      end
    end
  end
  return machines
end

-- When a player/robot removes the building
function Trainassembly:onRemoveEntity(removedEntity, buffer)
  -- In some way the building got removed. This results in that the builder is
  -- removed. This also means we have to delete the train that was in this spot.
  --
  -- Player experience: Everything with the trainAssembler gets removed
  if removedEntity.name == self:getMachineEntityName() then
    local entityPosition = removedEntity.position
    local entitySurface  = removedEntity.surface

    -- STEP 1: If the building created a train already, we need to delete it as well
    self:deleteCreatedTrainEntity(entitySurface.index, entityPosition)

    -- STEP 2: make the rails underneath minable again
    for _,railEntity in pairs(entitySurface.find_entities_filtered{
      name  = "straight-rail",
      type  = "straight-rail",
      --force = removedEntity.force,
      area  = {
        {entityPosition.x - 3.1, entityPosition.y - 3.1},
        {entityPosition.x + 3.1, entityPosition.y + 3.1},
      },
    }) do
      railEntity.destructible = true -- entity can be damaged
      railEntity.minable_flag      = true -- entity can be mined
    end

    -- STEP 3: Update the data structure
    self:deleteBuilding(removedEntity)

  elseif removedEntity.type == "straight-rail" or removedEntity.type == "legacy-straight-rail" then
    -- A rail under a Trainbuilder is removed (e.g. bots deconstruct the whole area and take
    -- the rail first): the Trainbuilder can't stay there. Give its item back and remove it.
    for _, machineEntity in pairs(self:getMachinesOnRail(removedEntity)) do
      local itemStack = {name = self:getItemName(), count = 1, quality = self:getQualityName(machineEntity.quality)}
      if not (buffer and buffer.valid and buffer.insert(itemStack) > 0) then
        machineEntity.surface.spill_item_stack{
          position = machineEntity.position,
          stack = itemStack,
          enable_looted = true,
          force = machineEntity.force,
          allow_belts = false,
        }
      end
      machineEntity.destroy{raise_destroy = true}
    end

  elseif self:isRollingStock(removedEntity) then
    if removedEntity.surface.count_entities_filtered{
      name     = self:getMachineEntityName(),
      position = removedEntity.position,
      force    = removedEntity.force,
      limit    = 1,
    } > 0 then
      self:setCreatedEntity(removedEntity.surface.index, removedEntity.position, nil)
    end
  end
end



-- Called after an entity dies.
function Trainassembly:onGhostBuild(removedEntityPrototype, ghostEntity)
  -- When the building gets removed, it can make a ghost so the bots will come
  -- replace it.
  if ghostEntity and removedEntityPrototype.name == self:getMachineEntityName() then
    rendering.draw_animation{
      animation = removedEntityPrototype.name .. "-" .. FLib.utils.directions.toString(ghostEntity.direction),
      tint = {r = 0.6, g = 0.6, b = 0.6, a = 0.3}, -- utility constant ghost_tint
      render_layer = "object",
      target = ghostEntity,
      surface = ghostEntity.surface,
    }
  end
end



-- When a player rotates an entity
function Trainassembly:onPlayerRotatedEntity(rotatedEntity)
  -- The player rotated the machine entity +/-90 degrees, the building can only be
  -- rotated on 180 degree angles. So we have to manualy rotate it another 90 degree.
  --
  -- Player experience: The player thinks he rotated the entity 180 degree
  if rotatedEntity.name == self:getMachineEntityName() then
    -- STEP 1: get the new direction from the old saved direction
    local newDirection = FLib.utils.directions.oposite(self:getMachineDirection(rotatedEntity))

    -- STEP 2: set the new rotated direction
    local renderIDs = self:getMachineRenderIDs(rotatedEntity)
    rotatedEntity.direction = newDirection
    if renderIDs then
      for _,animationLayer in pairs{"base", "overlay"} do
        if renderIDs[animationLayer] then
          compat.set_render_animation(renderIDs[animationLayer], rotatedEntity.name .. "-" .. FLib.utils.directions.toString(newDirection) .. "-" .. animationLayer)
        end
      end
    end

    -- STEP 3: save the state to the data structure
    self:updateMachineDirection(rotatedEntity)

    -- STEP 4: If the building created a train already, we need to rorate it as well
    local createdTrainEntity = self:getCreatedEntity(rotatedEntity.surface.index, rotatedEntity.position)
    if createdTrainEntity and createdTrainEntity.valid then
      createdTrainEntity.rotate()
      if createdTrainEntity.direction ~= newDirection then
        local createdTrainEntityStats = {
          type               = createdTrainEntity.type,
          name               = createdTrainEntity.name,
          surface            = createdTrainEntity.surface,
          position           = createdTrainEntity.position,
          direction          = newDirection,
          force              = createdTrainEntity.force,
          snap_to_train_stop = false,
          color              = createdTrainEntity.color
        }
        createdTrainEntity.destroy{raise_destroy=true}
        createdTrainEntity = createdTrainEntityStats.surface.create_entity(createdTrainEntityStats)
        local rotatedEntityRecipe = rotatedEntity.get_recipe()
        if rotatedEntityRecipe then
          for _,ingredient in pairs(rotatedEntityRecipe.ingredients) do
            if ingredient.name == "trainassembly-recipefuel" then
              createdTrainEntity.get_fuel_inventory().insert{
                name  = "trainassembly-trainfuel",
                count = ingredient.amount,
              }
            end
          end
        end
        createdTrainEntity.color = createdTrainEntityStats.color
        script.raise_event(defines.events.script_raised_built, {
          entity = createdTrainEntity
        })
        Trainassembly:setCreatedEntity(rotatedEntity.surface.index, rotatedEntity.position, createdTrainEntity)
      end
    end
  end
end



function Trainassembly:onPlayerChangedSettings(sourceEntity, destinationEntity)
  if sourceEntity     .name == self:getMachineEntityName() and
     destinationEntity.name == self:getMachineEntityName() then
    self:setMachineTint(destinationEntity, self:getMachineTint(sourceEntity))
  end
end



function Trainassembly:isFuelItem(itemName)
  -- Attempt to return cached value.
  -- If value doesn't exist, calculate it (expensive), cache it, and return
  storage.TA_data["fuelItems"] = storage.TA_data["fuelItems"] or {}
  local isFuelItem = storage.TA_data["fuelItems"][itemName]

  if isFuelItem == nil then
    local itemPrototype = prototypes.item[itemName]
    isFuelItem = itemPrototype and itemPrototype.fuel_value and itemPrototype.fuel_value > 0 or false
    storage.TA_data["fuelItems"][itemName] = isFuelItem
  end

  return isFuelItem
end
