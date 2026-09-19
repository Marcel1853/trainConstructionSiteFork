---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Trainassembly: Namen und Daten aus storage lesen.

--------------------------------------------------------------------------------
-- Getter functions to extract data from the data structure
--------------------------------------------------------------------------------
function Trainassembly:getItemName()
  return storage.TA_data.prototypeData.itemName
end



function Trainassembly:getPlaceableEntityName()
  return storage.TA_data.prototypeData.placeableName
end



function Trainassembly:getMachineEntityName()
  return storage.TA_data.prototypeData.machineName
end



function Trainassembly:isRollingStock(entity)
  return entity and entity.valid and storage.TA_data.prototypeData.rollingStock[entity.type] or false
end



function Trainassembly:getMachineEntity(machineSurfaceIndex, machinePosition)
  -- STEP 1: If we don't have a trainBuilder saved on that surface, or not
  --         on that y position or on that x position, it means that we don't
  --         have a entity available for that location.
  if not storage.TA_data["trainAssemblers"][machineSurfaceIndex] then
    return nil
  end
  if not storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y] then
    return nil
  end
  if not storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x] then
    return nil
  end

  -- STEP 2: In step 1 we checked for an invalid data structure. So now we
  --         can return the entity on this location.
  return storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x]["entity"]
end



function Trainassembly:getMachineDirection(machineEntity)
  -- STEP 1: If the machineEntity isn't valid, its position isn't valid either
  if not (machineEntity and machineEntity.valid) then
    return nil
  end

  -- STEP 2: If we don't have a trainBuilder saved on that surface, or not
  --         on that y position or on that x position, it means that we don't
  --         have a direction available for that machine.
  local machineSurface = machineEntity.surface
  if not storage.TA_data["trainAssemblers"][machineSurface.index] then
    return nil
  end
  local machinePosition = machineEntity.position
  if not storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y] then
    return nil
  end
  if not storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x] then
    return nil
  end

  -- STEP 3: In step 2 we checked for an invalid data structure. So now we
  --         can return the direction the machine is/was facing.
  return storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["direction"]
end



function Trainassembly:getMachineRenderIDs(machineEntity)
  -- STEP 1: If the machineEntity isn't valid, its position isn't valid either
  if not (machineEntity and machineEntity.valid) then
    return nil
  end

  -- STEP 2: If we don't have a trainBuilder saved on that surface, or not
  --         on that y position or on that x position, it means that we don't
  --         have a direction available for that machine.
  local machineSurface = machineEntity.surface
  if not storage.TA_data["trainAssemblers"][machineSurface.index] then
    return nil
  end
  local machinePosition = machineEntity.position
  if not storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y] then
    return nil
  end
  if not storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x] then
    return nil
  end

  -- STEP 3: In step 2 we checked for an invalid data structure. So now we
  --         can return the direction the machine is/was facing.
  return storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["renderID"]
end



function Trainassembly:getMachineTint(machineEntity)
  -- STEP 1: If the machineEntity isn't valid, its position isn't valid either
  if not (machineEntity and machineEntity.valid) then
    return nil
  end

  -- STEP 2: If we don't have a trainBuilder saved on that surface, or not
  --         on that y position or on that x position, it means that we don't
  --         have a direction available for that machine.
  local machineSurface = machineEntity.surface
  if not storage.TA_data["trainAssemblers"][machineSurface.index] then
    return nil
  end
  local machinePosition = machineEntity.position
  if not storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y] then
    return nil
  end
  if not storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x] then
    return nil
  end

  -- STEP 3: In step 2 we checked for an invalid data structure. So now we
  --         can return the direction the machine is/was facing.
  return storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainColor"]
end



function Trainassembly:getCreatedEntity(machineSurfaceIndex, machinePosition)
  -- STEP 1: If we don't have a trainBuilder saved on that surface, or not
  --         on that y position or on that x position, it means that we don't
  --         have a entity available for that location.
  if not storage.TA_data["trainAssemblers"][machineSurfaceIndex] then
    return nil
  end
  if not storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y] then
    return nil
  end
  if not storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x] then
    return nil
  end

  -- STEP 2: In step 1 we checked for an invalid data structure. So now we
  --         can return the entity on this location.
  return storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x]["createdEntity"]
end



function Trainassembly:getTrainBuilderIndex(machineEntity)
  -- STEP 1: If the machineEntity isn't valid, its position isn't valid either
  if not (machineEntity and machineEntity.valid) then
    return nil
  end

  -- STEP 2: If we don't have a trainBuilder saved on that surface, or not
  --         on that y position or on that x position, it means that we don't
  --         have a trainBuilderIndex available for that machine.
  local machineSurface = machineEntity.surface
  if not storage.TA_data["trainAssemblers"][machineSurface.index] then
    return nil
  end
  local machinePosition = machineEntity.position
  if not storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y] then
    return nil
  end
  if not storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x] then
    return nil
  end

  -- STEP 3: In step 2 we checked for an invalid data structure. So now we
  --         can return the trainBuilderIndex of the machine.
  return storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainBuilderIndex"]
end



function Trainassembly:getTrainBuilder(trainBuilderIndex)
  --step 1: Make sure there is a valid index
  if not trainBuilderIndex then return nil end

  --step 2: In this step we return the trainBuilders with the trainBuilderIndex.
  return storage.TA_data["trainBuilders"][trainBuilderIndex]
end



function Trainassembly:getTrainBuilderIterator(dir)
  return function(t)
    -- Ordered table iterator, allow to iterate in the order that the trainBuilder
    -- connects the train together. Equivalent of the pairs() function on tables.
    -- Allows to iterate in order.

    local function iteratorNext(t, state)
      -- Equivalent of the next function, but returns the keys in order that the
      -- trainbuilder will build. We use a temporary ordered key table that is
      -- stored in the table being iterated.

      local function __genIteratorIndex(t)
        -- generate the index
        local pos = (dir == defines.direction.east or dir == defines.direction.west) and "x" or "y"

        -- first sort the values
        local orderedValues = {}
        local orderedValuesIndex = 1
        for _,val in pairs(t) do
          -- table.insert(orderedIndex, key)
          orderedValues[orderedValuesIndex] = val.position[pos]
          orderedValuesIndex = orderedValuesIndex + 1
        end
        table.sort(orderedValues)

        if dir == defines.direction.east  or
           dir == defines.direction.south then
          -- invert order
          local i, j = 1, #orderedValues
          while i < j do
            orderedValues[i], orderedValues[j] = orderedValues[j], orderedValues[i]
            i = i + 1
            j = j - 1
          end
        end

        -- now that we know the order of the values, we can remap these values to there keys
        local orderedIndex = {}
        for orderedIdexIndex, orderedValue in pairs(orderedValues) do
          local orderedValueFound = false
          for key,val in pairs(t) do -- obtain the key that is linked to this orderedValue
            if (not orderedValueFound) and (val.position[pos] == orderedValue) then
              orderedIndex[orderedIdexIndex] = key
              orderedValueFound = true
            end
          end
        end

        -- now the values are ordened and we got an ordened list of these keys
        return orderedIndex
      end

      local key = nil
      --print("iteratorNext: state = "..tostring(state) )
      if state == nil then
        -- the first time, generate the index
        t.__iteratorIndex = __genIteratorIndex(t)
        key = t.__iteratorIndex[1]
      else
        -- fetch the next value
        for i = 1, #t.__iteratorIndex do
          if t.__iteratorIndex[i] == state then
            key = t.__iteratorIndex[i+1]
          end
        end
      end

      if key then
        return key, t[key]
      end

      -- no more value to return, cleanup
      t.__iteratorIndex = nil
      return
    end

    return iteratorNext, t, nil
  end
end



function Trainassembly:getTrainTint(trainEntityName)
  if not storage.TA_data.prototypeData.trainTint[trainEntityName] then
    -- value not cached yet
    local entityPrototype = prototypes.entity[trainEntityName]
    if not entityPrototype then return {} end

    storage.TA_data.prototypeData.trainTint[trainEntityName] = entityPrototype.color or {}
  end

  return storage.TA_data.prototypeData.trainTint[trainEntityName]
end
