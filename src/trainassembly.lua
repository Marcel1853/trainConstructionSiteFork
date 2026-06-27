---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
require 'util'
require("compat.lslib")
local compat = require("compat.factorio_2")
local trainRecipe = require("compat.train_recipe")

-- Create class
Trainassembly = {}

local function getEntity4WayDirection(entity)
  local direction = entity and entity.direction
  if direction == defines.direction.north or
     direction == defines.direction.east  or
     direction == defines.direction.south or
     direction == defines.direction.west then
    return direction
  end
  return FLib.utils.directions.orientationTo4WayDirection(entity and entity.orientation or 0)
end

--------------------------------------------------------------------------------
-- Initiation of the class
--------------------------------------------------------------------------------
function Trainassembly:onInit()
  -- Init global data; data stored through the whole map
  if not storage.TA_data then
    storage.TA_data = self:initGlobalData()
  end
end



-- Initiation of the global data
function Trainassembly:initGlobalData()
  local TA_data = {
    ["version"] = 8, -- version of the global data
    ["prototypeData"] = self:initPrototypeData(), -- data storing info about the prototypes

    ["trainAssemblers"] = {}, -- keep track of all assembling machines

    ["trainBuilders"] = {}, -- keep track of all builders that contain one or more trainAssemblers
    ["nextTrainBuilderIndex"] = 1, -- next free space in the trainBuilders table
    ["fuelItems"] = {}, -- cache to more efficiently decide if an item is fuel or not
  }

  return util.table.deepcopy(TA_data)
end



-- Initialisation of the prototye data inside the global data
function Trainassembly:initPrototypeData()
  return
  {
    ["itemName"     ] = "trainassembly",           -- the item
    ["placeableName"] = "trainassembly-placeable", -- locomotive entity
    ["machineName"  ] = "trainassembly-machine",   -- assembling entity

    ["trainTint"    ] = {},                        -- the tint of each created entity
    ["rollingStock" ] = {                          -- the types of rolling stocks
      ["locomotive"     ] = true,
      ["cargo-wagon"    ] = true,
      ["fluid-wagon"    ] = true,
      ["artillery-wagon"] = true,
    },
  }
end



--------------------------------------------------------------------------------
-- Setter functions to alter data into the data structure
--------------------------------------------------------------------------------
-- Save a new trainassembly to our data structure
function Trainassembly:saveNewStructure(machineEntity, machineRenderID)
  -- With this function we save all the data we want about a trainassembly.
  -- To index all machines we need a (unique) way of storing all the data,
  -- here we chose to index it by its location, since only 1 building can
  -- be standing in 1 place. So we index it by surface and position.

  -- STEP 1: This step should be obsolite, we need to check if the entity is
  --         valid, if not, the surface and position it was placed on will
  --         be invalid as well.
  if not (machineEntity and machineEntity.valid) then
    return nil
  end
  local machineSurface  = machineEntity.surface
  local machinePosition = machineEntity.position

  -- STEP 2: Save the assembler in the trainAssemblers datastructure
  -- STEP 2a:Make sure we can index it, meaning, check if the table already
  --         excists for the surface, if not, we make one. Afther that we also
  --         have to check if the surface table has a table we can index for
  --         the y-position, if not, we make one.
  if not storage.TA_data["trainAssemblers"][machineSurface.index] then
    storage.TA_data["trainAssemblers"][machineSurface.index] = {}
  end
  if not storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y] then
    storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y] = {}
  end

  -- STEP 2b:Now we know we can index (without crashing) to the position as:
  --         dataStructure[surfaceIndex][positionY][positionX]
  --         Now we can store our wanted data at this position
  storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x] =
  {
    ["entity"           ] = machineEntity,           -- the entity
    ["renderID"         ] = machineRenderID,         -- the renders of the building
    ["direction"        ] = machineEntity.direction, -- the direction its facing
    ["trainColor"       ] = FLib.utils.table.convertRGBA{r = 234, g = 17, b = 0}, -- the color of the train entity when it will be created
    ["pendingQuality"   ] = "normal",                -- quality of the next train entity to create
    ["createdEntity"    ] = nil,                     -- the created train entity from this building
    ["trainBuilderIndex"] = nil,                     -- the trainBuilder it belongs to (see further down)
  }

  -- STEP 3: Check if this assembler is linked to another assemblers to make
  --         single but bigger trains
  -- STEP 3a:Check for entities around this one. We know we only have to look
  --         in the same direction as its facing, as that is the directon the
  --         train will be build in
  local trainAssemblerNW, trainAssemblerSE
  if machineEntity.direction == defines.direction.north or machineEntity.direction == defines.direction.south then
    -- machine is placed vertical, look vertical (y-axis)
    -- north
    trainAssemblerNW = machineSurface.find_entities_filtered{
      name     = machineEntity.name,
      type     = machineEntity.type,
      force    = machineEntity.force,
      position = { x = machinePosition.x, y = machinePosition.y - 7 },
      limit    = 1,
    }
    -- south
    trainAssemblerSE = machineSurface.find_entities_filtered{
      name     = machineEntity.name,
      type     = machineEntity.type,
      force    = machineEntity.force,
      position = { x = machinePosition.x, y = machinePosition.y + 7 },
      limit    = 1,
    }
  else
    -- machine is placed horizontal, look horizontal (x-axis)
    -- west
    trainAssemblerNW = machineSurface.find_entities_filtered{
      name     = machineEntity.name,
      type     = machineEntity.type,
      force    = machineEntity.force,
      position = { x = machinePosition.x - 7, y = machinePosition.y },
      limit    = 1,
    }
    -- east
    trainAssemblerSE = machineSurface.find_entities_filtered{
      name     = machineEntity.name,
      type     = machineEntity.type,
      force    = machineEntity.force,
      position = { x = machinePosition.x + 7, y = machinePosition.y },
      limit    = 1,
    }
  end

  -- find_entities_filtered returns a list, we want only the entity,
  -- so we get it out of the table. Also make sure it is valid
  if not FLib.utils.table.isEmpty(trainAssemblerNW) then
    trainAssemblerNW = trainAssemblerNW[1]
    if not trainAssemblerNW.valid then
      trainAssemblerNW = nil
    end
  else
    trainAssemblerNW = nil
  end
  if not FLib.utils.table.isEmpty(trainAssemblerSE) then
    trainAssemblerSE = trainAssemblerSE[1]
    if not trainAssemblerSE.valid then
      trainAssemblerSE = nil
    end
  else
    trainAssemblerSE = nil
  end

  -- STEP 3b:We found some entities now (maybe), but we still have to check if
  --         they are validly placed. If they aren't valid, we discard them too
  --         Validly placed item: - has same or oposite direction
  if trainAssemblerNW and trainAssemblerNW.valid then
    -- Check if its facing the same or oposite direction, if not, discard.
    if not (trainAssemblerNW.direction == machineEntity.direction
            or trainAssemblerNW.direction == FLib.utils.directions.oposite(machineEntity.direction) ) then
      trainAssemblerNW = nil
    end
  end
  if trainAssemblerSE and trainAssemblerSE.valid then
    -- Check if its facing the same or oposite direction, if not, discard.
    if not (trainAssemblerSE.direction == machineEntity.direction
            or trainAssemblerSE.direction == FLib.utils.directions.oposite(machineEntity.direction) ) then
      trainAssemblerSE = nil
    end
  end

  -- STEP 3c:We found valid entities (maybe), either way, we have to add this
  --         assembling machine to a trainBuilder
  if (not trainAssemblerNW) and (not trainAssemblerSE) then
    -- OPTION 3c.1: there is no neighbour detected, we create a new one
    local trainBuilderIndex = storage.TA_data["nextTrainBuilderIndex"]

    -- add reference to the trainassembly
    storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainBuilderIndex"] = trainBuilderIndex

    -- and add the new trainBuilder with a single trainAssembler reference
    storage.TA_data["trainBuilders"][trainBuilderIndex] =
    {
      {
        ["surfaceIndex"] = machineSurface.index,
        ["position"]     = { x = machinePosition.x, y = machinePosition.y },
      },
    }

    -- new trainbuilder added, now increment the nextIndex
    storage.TA_data["nextTrainBuilderIndex"] = trainBuilderIndex + 1

  else -- there is one or more neighbours
    if (trainAssemblerNW and (not trainAssemblerSE)) then
      -- OPTION 3c.2a: There is only one neighbour detected.
      --               Only the northwest one was detected, we add it to his
      --               trainbuilder.
      local trainBuilderIndex = storage.TA_data["trainAssemblers"][trainAssemblerNW.surface.index][trainAssemblerNW.position.y][trainAssemblerNW.position.x]["trainBuilderIndex"]
      Traincontroller:onTrainbuilderAltered(trainBuilderIndex)

      -- add reference to the trainBuilder in the trainassembly
      storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainBuilderIndex"] = trainBuilderIndex

      -- and add this trainAssembler reference to the existing trainBuilder
      table.insert(storage.TA_data["trainBuilders"][trainBuilderIndex], {
        ["surfaceIndex"] = machineSurface.index,
        ["position"]     = { x = machinePosition.x, y = machinePosition.y },
      })

    elseif (trainAssemblerSE and (not trainAssemblerNW)) then
      -- OPTION 3c.2b: There is only one neighbour detected.
      --               Only the southeast one was detected, we add it to his
      --               trainbuilder.
      local trainBuilderIndex = storage.TA_data["trainAssemblers"][trainAssemblerSE.surface.index][trainAssemblerSE.position.y][trainAssemblerSE.position.x]["trainBuilderIndex"]
      Traincontroller:onTrainbuilderAltered(trainBuilderIndex)

      -- add reference to the trainBuilder in the trainassembly
      storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainBuilderIndex"] = trainBuilderIndex

      -- and add this trainAssembler reference to the existing trainBuilder
      table.insert(storage.TA_data["trainBuilders"][trainBuilderIndex], {
        ["surfaceIndex"] = machineSurface.index,
        ["position"]     = { x = machinePosition.x, y = machinePosition.y },
      })

    else
      -- OPTION 3c.3: Both neighbours are detected
      --              First we need to merge the two existing trainBuilders
      --              together. Let's merge the SE one inside the NW one
      local nwSurf = trainAssemblerNW.surface and trainAssemblerNW.surface.index
      local nwPosY = trainAssemblerNW.position and trainAssemblerNW.position.y
      local nwPosX = trainAssemblerNW.position and trainAssemblerNW.position.x
      local seSurf = trainAssemblerSE.surface and trainAssemblerSE.surface.index
      local sePosY = trainAssemblerSE.position and trainAssemblerSE.position.y
      local sePosX = trainAssemblerSE.position and trainAssemblerSE.position.x
      if not (nwSurf and nwPosY and nwPosX and seSurf and sePosY and sePosX) then return end
      local trainBuilderIndexNW = storage.TA_data["trainAssemblers"][nwSurf][nwPosY][nwPosX]["trainBuilderIndex"]
      local trainBuilderIndexSE = storage.TA_data["trainAssemblers"][seSurf][sePosY][sePosX]["trainBuilderIndex"]
      Traincontroller:onTrainbuilderAltered(trainBuilderIndexNW)
      Traincontroller:onTrainbuilderAltered(trainBuilderIndexSE)

      for trainAssemblerIndex, trainAssemblerRef in pairs(storage.TA_data["trainBuilders"][trainBuilderIndexSE]) do
        -- Move the reference into the other trainBuilder
        table.insert(storage.TA_data["trainBuilders"][trainBuilderIndexNW], util.table.deepcopy(trainAssemblerRef))
      end

      -- Now all the assemblers of the SE one are in the NW one, we can now delete
      -- the whole SE trainbuilder. If we delete it, we have a 'hole' in our list
      -- to fix that, we move the last one in this spot * fixed XD *. But if this
      -- is already the last one, we don't have this issue. And when we move the're
      -- is a possibility we moved the NW over. We've also deleted a trainbuiler,
      -- so we'll have to update our nextIndex - 1.
      local lastIndex = storage.TA_data["nextTrainBuilderIndex"] - 1

      -- check if its the last one, if not the last one we fill the hole of the SE one
      if (trainBuilderIndexSE ~= lastIndex) then
        -- copy the last one over to the hole and adapt all the references to the
        -- trianBuilder of all the trainAssemblers we moved
        storage.TA_data["trainBuilders"][trainBuilderIndexSE] = util.table.deepcopy(storage.TA_data["trainBuilders"][lastIndex])
        for _, trainAssemblerRef in pairs(storage.TA_data["trainBuilders"][trainBuilderIndexSE]) do
          storage.TA_data["trainAssemblers"][trainAssemblerRef.surfaceIndex][trainAssemblerRef.position.y][trainAssemblerRef.position.x]["trainBuilderIndex"] = trainBuilderIndexSE
        end

        -- it could be the other one we moved
        if trainBuilderIndexNW == lastIndex then
          trainBuilderIndexNW = trainBuilderIndexSE
        end
      end

      -- delete the reference of the last index
      storage.TA_data["trainBuilders"][lastIndex] = nil
      storage.TA_data["nextTrainBuilderIndex"] = lastIndex

      -- and add this trainAssembler reference to that existing trainBuilder
      table.insert(storage.TA_data["trainBuilders"][trainBuilderIndexNW], {
        ["surfaceIndex"] = machineSurface.index,
        ["position"]     = { x = machinePosition.x, y = machinePosition.y },
      })

      -- now we finaly merged them both together and added the new assembler, now
      -- we can start updating the reference in the trainassembly to the trainbuilders
      --storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainBuilderIndex"] = trainBuilderIndexNW
      for _, trainAssemblerRef in pairs(storage.TA_data["trainBuilders"][trainBuilderIndexNW]) do
        storage.TA_data["trainAssemblers"][trainAssemblerRef.surfaceIndex][trainAssemblerRef.position.y][trainAssemblerRef.position.x]["trainBuilderIndex"] = trainBuilderIndexNW
      end
    end
  end

end



function Trainassembly:deleteBuilding(machineEntity)

  --Step 1: check if the machineEntity is valid.
  if not (machineEntity and machineEntity.valid) then
    return nil
  end
  local machineSurface  = machineEntity.surface
  local machinePosition = machineEntity.position

  --Step 2a: check what direction it is facing (vertical or horizontal)
  local trainAssemblerNW, trainAssemblerSE
  if machineEntity.direction == defines.direction.north or machineEntity.direction == defines.direction.south then
    -- machine is placed vertical, look vertical (y-axis)
    -- north
    trainAssemblerNW = machineSurface.find_entities_filtered{
      name     = machineEntity.name,
      type     = machineEntity.type,
      force    = machineEntity.force,
      position = { x = machinePosition.x, y = machinePosition.y - 7 },
      limit    = 1,
    }
    -- south
    trainAssemblerSE = machineSurface.find_entities_filtered{
      name     = machineEntity.name,
      type     = machineEntity.type,
      force    = machineEntity.force,
      position = { x = machinePosition.x, y = machinePosition.y + 7 },
      limit    = 1,
    }
  else
    -- machine is placed horizontal, look horizontal (x-axis)
    -- west
    trainAssemblerNW = machineSurface.find_entities_filtered{
      name     = machineEntity.name,
      type     = machineEntity.type,
      force    = machineEntity.force,
      position = { x = machinePosition.x - 7, y = machinePosition.y },
      limit    = 1,
    }
    -- east
    trainAssemblerSE = machineSurface.find_entities_filtered{
      name     = machineEntity.name,
      type     = machineEntity.type,
      force    = machineEntity.force,
      position = { x = machinePosition.x + 7, y = machinePosition.y },
      limit    = 1,
    }
  end

  -- find_entities_filtered returns a list, we want only the entity,
  -- so we get it out of the table. Also make sure it is valid
  if not FLib.utils.table.isEmpty(trainAssemblerNW) then
    trainAssemblerNW = trainAssemblerNW[1]
    if not trainAssemblerNW.valid then
      trainAssemblerNW = nil
    end
  else
    trainAssemblerNW = nil
  end
  if not FLib.utils.table.isEmpty(trainAssemblerSE) then
    trainAssemblerSE = trainAssemblerSE[1]
    if not trainAssemblerSE.valid then
      trainAssemblerSE = nil
    end
  else
    trainAssemblerSE = nil
  end

  -- STEP 2b: We found some entities now (maybe), but we still have to check if
  --          they are validly placed. If they aren't valid, we discard them too
  --          Validly placed item: - has same or oposite direction
  if trainAssemblerNW and trainAssemblerNW.valid then
    -- Check if its facing the same or oposite direction, if not, discard.
    if not (trainAssemblerNW.direction == machineEntity.direction
            or trainAssemblerNW.direction == FLib.utils.directions.oposite(machineEntity.direction) ) then
      trainAssemblerNW = nil
    end
  end
  if trainAssemblerSE and trainAssemblerSE.valid then
    -- Check if its facing the same or oposite direction, if not, discard.
    if not (trainAssemblerSE.direction == machineEntity.direction
            or trainAssemblerSE.direction == FLib.utils.directions.oposite(machineEntity.direction) ) then
      trainAssemblerSE = nil
    end
  end

  -- STEP 2c: Now that we found the entities, we can start updating the trainBuilder
  if (not trainAssemblerNW) and (not trainAssemblerSE) then
    local trainBuilderIndex = storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainBuilderIndex"]
    Traincontroller:onTrainbuilderAltered(trainBuilderIndex)

    storage.TA_data["trainBuilders"][trainBuilderIndex] = nil
    local lastTrainBuilderIndex = storage.TA_data["nextTrainBuilderIndex"] - 1

    if trainBuilderIndex ~= lastTrainBuilderIndex then
      storage.TA_data["trainBuilders"][trainBuilderIndex] = util.table.deepcopy(storage.TA_data["trainBuilders"][lastTrainBuilderIndex])

      -- update all the trainAssemblers
      for _, location in pairs(storage.TA_data["trainBuilders"][trainBuilderIndex]) do
        storage.TA_data["trainAssemblers"][location["surfaceIndex"]][location["position"].y][location["position"].x]["trainBuilderIndex"] = trainBuilderIndex
      end

    end

    storage.TA_data["nextTrainBuilderIndex"] = lastTrainBuilderIndex

  else -- there is one or more neighbours

    if (trainAssemblerNW and (not trainAssemblerSE)) or (trainAssemblerSE and (not trainAssemblerNW)) then -- only one neighbour

      local trainBuilderIndex = storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainBuilderIndex"]
      Traincontroller:onTrainbuilderAltered(trainBuilderIndex)

      -- delete the assembler out of the trainbuilder
      for locationIndex, location in pairs(storage.TA_data["trainBuilders"][trainBuilderIndex]) do
        if location["surfaceIndex"] == machineSurface.index and location["position"].y == machinePosition.y and location["position"].x == machinePosition.x then
          table.remove(storage.TA_data["trainBuilders"][trainBuilderIndex], locationIndex)
          break
        end
      end

    else -- there are two neighbours

      local trainBuilderIndex  = storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainBuilderIndex"]
      Traincontroller:onTrainbuilderAltered(trainBuilderIndex)
      local newTrainBuilderIndex = storage.TA_data["nextTrainBuilderIndex"]
      storage.TA_data["trainBuilders"][newTrainBuilderIndex] = {}

      local builderIsVertical = false
      if trainAssemblerNW and trainAssemblerNW.direction == defines.direction.north then
        builderIsVertical = true
      end

      -- delete the assembler out of the trainbuilder
      for locationIndex, location in pairs(storage.TA_data["trainBuilders"][trainBuilderIndex]) do
        if location["surfaceIndex"] == machineSurface.index and location["position"].y == machinePosition.y and location["position"].x == machinePosition.x then
          table.remove(storage.TA_data["trainBuilders"][trainBuilderIndex], locationIndex)
          break
        end
      end
      
      for locationIndex, location in pairs(storage.TA_data["trainBuilders"][trainBuilderIndex]) do
        local needToMove = false

        if builderIsVertical then
          if location["position"].y < machinePosition.y then
            needToMove = true
          end
        else
          if location["position"].x < machinePosition.x then
            needToMove = true
          end
        end

        if needToMove then --moving assemblers over to different builder
          table.insert(storage.TA_data["trainBuilders"][newTrainBuilderIndex], util.table.deepcopy(storage.TA_data["trainBuilders"][trainBuilderIndex][locationIndex])) --copy over to different builder
          storage.TA_data["trainBuilders"][trainBuilderIndex][locationIndex] = nil --delete the old one
          storage.TA_data["trainAssemblers"][location["surfaceIndex"]][location["position"].y][location["position"].x]["trainBuilderIndex"] = newTrainBuilderIndex --adjusting trainbuilderindex in assembler
        end
      end

      storage.TA_data["nextTrainBuilderIndex"] = newTrainBuilderIndex + 1
    end
  end

  -- STEP 3: Deleting the trainAssembler
  storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x] = nil

  if FLib.utils.table.isEmpty(storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y]) then
    storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y] = nil

    if FLib.utils.table.isEmpty(storage.TA_data["trainAssemblers"][machineSurface.index]) then
      storage.TA_data["trainAssemblers"][machineSurface.index] = nil
    end
  end

end



function Trainassembly:updateMachineDirection(machineEntity)

  if not (machineEntity and machineEntity.valid) then
    return nil
  end
  local machineSurface  = machineEntity.surface
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

  storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["direction"] = machineEntity.direction

end



function Trainassembly:setMachineTint(machineEntity, tintColor)

  if not (machineEntity and machineEntity.valid) then
    return nil
  end
  local machineSurface  = machineEntity.surface
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

  storage.TA_data["trainAssemblers"][machineSurface.index][machinePosition.y][machinePosition.x]["trainColor"] = {
    r = tintColor.r or 0,
    g = tintColor.g or 0,
    b = tintColor.b or 0,
  }

end





function Trainassembly:getQualityName(quality)
  if type(quality) == "string" then return quality end
  if type(quality) == "userdata" and quality.valid then return quality.name end
  if type(quality) == "table" and quality.name then return quality.name end
  return "normal"
end



function Trainassembly:getQualityLevel(quality)
  local qualityName = self:getQualityName(quality)
  local qualityPrototype = prototypes.quality and prototypes.quality[qualityName]
  return qualityPrototype and qualityPrototype.level or 0
end



function Trainassembly:setPendingQuality(machineEntity, quality)
  if not (machineEntity and machineEntity.valid) then return false end
  local machineSurfaceIndex = machineEntity.surface.index
  local machinePosition = machineEntity.position
  if not (storage.TA_data["trainAssemblers"][machineSurfaceIndex] and
          storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y] and
          storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x]) then
    return false
  end
  storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x]["pendingQuality"] = self:getQualityName(quality)
  return true
end



function Trainassembly:getPendingQuality(machineSurfaceIndex, machinePosition)
  if not (storage.TA_data["trainAssemblers"][machineSurfaceIndex] and
          storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y] and
          storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x]) then
    return "normal"
  end
  return storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x]["pendingQuality"] or "normal"
end



function Trainassembly:getTrainPartIngredientName(machineRecipe)
  if not machineRecipe then return nil end
  for _, ingredient in pairs(machineRecipe.ingredients or {}) do
    if ingredient.type == "item" and ingredient.name ~= "trainassembly-recipefuel" then
      return ingredient.name
    end
  end
  return nil
end



function Trainassembly:capturePendingQuality(machineEntity, machineRecipe)
  -- The train assembly recipes output a fluid marker because that is how the
  -- original mod detects a completed build. Fluids have no quality, so capture
  -- the quality of the train-part item while it is still in the machine input
  -- inventory, then apply that quality when the rolling stock is created.
  if not (machineEntity and machineEntity.valid and script.feature_flags and script.feature_flags.quality) then
    return "normal"
  end

  local ingredientName = self:getTrainPartIngredientName(machineRecipe)
  if not ingredientName then return "normal" end

  local inputInventoryIndex = defines.inventory.crafter_input or defines.inventory.assembling_machine_input
  local inputInventory = machineEntity.get_inventory(inputInventoryIndex)
  if not (inputInventory and inputInventory.valid) then return self:getPendingQuality(machineEntity.surface.index, machineEntity.position) end

  local bestQuality = nil
  local bestLevel = -1
  for _, content in pairs(inputInventory.get_contents() or {}) do
    if content.name == ingredientName and content.count and content.count > 0 then
      local qualityName = self:getQualityName(content.quality)
      local qualityLevel = self:getQualityLevel(qualityName)
      if qualityLevel > bestLevel then
        bestQuality = qualityName
        bestLevel = qualityLevel
      end
    end
  end

  if bestQuality then
    self:setPendingQuality(machineEntity, bestQuality)
    return bestQuality
  end

  return self:getPendingQuality(machineEntity.surface.index, machineEntity.position)
end


function Trainassembly:setCreatedEntity(machineSurfaceIndex, machinePosition, createdEntity)
  -- STEP 1: If we don't have a trainBuilder saved on that surface, or not
  --         on that y position or on that x position, it means that we don't
  --         have a entity available for that location.
  if not storage.TA_data["trainAssemblers"][machineSurfaceIndex] then
    return false
  end
  if not storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y] then
    return false
  end
  if not storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x] then
    return false
  end

  -- STEP 2: In step 1 we checked for an invalid data structure. So now we
  --         can return the entity on this location.
  storage.TA_data["trainAssemblers"][machineSurfaceIndex][machinePosition.y][machinePosition.x]["createdEntity"] = createdEntity
  return true
end



function Trainassembly:deleteCreatedTrainEntity(machineSurfaceIndex, machinePosition)
  -- delete the createdEntity from a trainBuilder
  local createdTrainEntity = self:getCreatedEntity(machineSurfaceIndex, machinePosition)
  if createdTrainEntity and createdTrainEntity.valid then
    createdTrainEntity.destroy()
    self:setCreatedEntity(machineSurfaceIndex, machinePosition, nil)

    -- attempt to put the train back in the recipe result.
    local machineEntity = self:getMachineEntity(machineSurfaceIndex, machinePosition)
    if machineEntity and machineEntity.valid then
      local machineRecipe = machineEntity.get_recipe()
      if machineRecipe then
        machineEntity.insert_fluid({
          name = machineRecipe.products[1].name,
          amount = 1
        })
      end
    end
  end
end



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

-- When a player/robot removes the building
function Trainassembly:onRemoveEntity(removedEntity)
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

  elseif removedEntity.name == "straight-rail" then
    -- If a rail under a Trainbuilder is removed, the Trainbuilder is no longer
    -- valid. Remove the associated machine as well to avoid floating builders.
    local machineEntity = removedEntity.surface.find_entities_filtered{
      name  = self:getMachineEntityName(),
      type  = "assembling-machine",
      area  = {{x = removedEntity.position.x - .5, y = removedEntity.position.y - .5},
               {x = removedEntity.position.x + .5, y = removedEntity.position.y + .5},},
      limit = 1,
    }[1]
    if machineEntity and machineEntity.valid then
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
