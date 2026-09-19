---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Trainassembly: Qualität der gebauten Zug-Entities.

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
