---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Trainassembly: Wagen speichern, löschen, drehen, einfärben und erzeugte Zug-Entities verwalten.

--------------------------------------------------------------------------------
-- Setter functions to alter data into the data structure
--------------------------------------------------------------------------------
-- Save a new trainassembly to our data structure
function Trainassembly:saveNewStructure(machineEntity, machineRenderID, receiver)
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

  -- STEP 3: Link this assembler to its neighbours (same or new trainBuilder),
  --         see scripts/assembly/builders.lua
  self:addToTrainBuilder(machineEntity, receiver)
end



function Trainassembly:deleteBuilding(machineEntity, receiver)
  --Step 1: check if the machineEntity is valid.
  if not (machineEntity and machineEntity.valid) then
    return nil
  end
  local machineSurface  = machineEntity.surface
  local machinePosition = machineEntity.position
  if not self:getAssemblerData(machineSurface.index, machinePosition) then
    return nil -- already deleted (e.g. destroy with raise_destroy inside another handler)
  end

  --Step 2: take the assembler out of its trainBuilder (splits the builder if needed),
  --        see scripts/assembly/builders.lua
  self:removeFromTrainBuilder(machineEntity, receiver)

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
