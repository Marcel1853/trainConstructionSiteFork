---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Datenstand von Trainassembly (storage.TA_data) hochziehen.
-- Teil von on_configuration_changed, siehe init.lua.

local compat = require("compat.factorio_2")

return function()
  --------------------------------------------------
  -- Trainassembly script                         --
  --------------------------------------------------
  if storage.TA_data.version == 1 then
    log("Updating Trainassembly from version 1 to version 2.")
    storage.TA_data.prototypeData.trainTint = {}
    storage.TA_data.version = 2
  end

  if storage.TA_data.version == 2 then
    log("Updating Trainassembly from version 2 to version 3.")
    storage.TA_data.prototypeData.rollingStock =
    {
      ["locomotive"     ] = true,
      ["cargo-wagon"    ] = true,
      ["fluid-wagon"    ] = true,
      ["artillery-wagon"] = true,
    }
    storage.TA_data.version = 3
  end

  if storage.TA_data.version == 3 then
    log("Updating Trainassembly from version 3 to version 4.")
    for machineSurface,machineSurfaceData in pairs(storage.TA_data and storage.TA_data["trainAssemblers"] or {}) do
      for machinePositionY, machinePositionData in pairs(machineSurfaceData) do
        for machinePositionX, machineData in pairs(machinePositionData) do
          local renderIDs = {}
          local machineEntity = machineData.entity
          for animationLayer,renderLayer in pairs{
            ["base"] = "lower-object",
            ["overlay"] = "item-in-inserter-hand"
          } do
            renderIDs[animationLayer] = rendering.draw_animation{
              animation = machineEntity.name .. "-" .. FLib.utils.directions.toString(machineEntity.direction) .. "-" .. animationLayer,
              render_layer = renderLayer,
              target = machineEntity,
              surface = machineEntity.surface,
            }
          end
          storage.TA_data["trainAssemblers"][machineSurface][machinePositionY][machinePositionX]["renderID"] = renderIDs
        end
      end
    end
    storage.TA_data.version = 4
  end

  if storage.TA_data.version == 4 then
    log("Updating Trainassembly from version 4 to version 5.")
    local trainBuilderIndices = {}
    for machineSurface,machineSurfaceData in pairs(storage.TA_data and storage.TA_data["trainAssemblers"] or {}) do
      for machinePositionY, machinePositionData in pairs(machineSurfaceData) do
        for machinePositionX, machineData in pairs(machinePositionData) do
          trainBuilderIndices[machineData.trainBuilderIndex] = (trainBuilderIndices[machineData.trainBuilderIndex] or 0) + 1
          if machineData.createdEntity and machineData.createdEntity.valid then
          else
            machineData.createdEntity = nil
          end
        end
      end
    end
    for trainBuilderIndex, trainBuilder in pairs(storage.TA_data and storage.TA_data["trainBuilders"] or {}) do
      if trainBuilderIndices[trainBuilderIndex] then
      else
        local newTrainBuilder = {}
        for _, trainAssembler in pairs(trainBuilder) do
          local found = false
          for machineSurface,machineSurfaceData in pairs(storage.TA_data and storage.TA_data["trainAssemblers"] or {}) do
            if trainAssembler.surfaceIndex == machineSurface then
              for machinePositionY, machinePositionData in pairs(machineSurfaceData) do
                if trainAssembler.position.y == machinePositionY then
                  for machinePositionX, machineData in pairs(machinePositionData) do
                    if trainAssembler.position.x == machinePositionX then
                      found = true
                    end
                  end
                end
              end
            end
          end
          if not found then
            table.insert(newTrainBuilder, util.table.deepcopy(trainAssembler))
          end
        end
        if #newTrainBuilder > 0 then
          storage.TA_data["trainBuilders"][trainBuilderIndex] = newTrainBuilder
        else
          storage.TA_data["trainBuilders"][trainBuilderIndex] = nil
        end
      end
    end
    storage.TA_data.version = 5
  end

  if storage.TA_data.version == 5 then
    log("Updating Trainassembly from version 5 to version 6 (Factorio 2.0 directions).")
    local oldToNewDirection = {
      [0] = defines.direction.north,
      [2] = defines.direction.east,
      [4] = defines.direction.south,
      [6] = defines.direction.west,
    }
    for _, machineSurfaceData in pairs(storage.TA_data and storage.TA_data["trainAssemblers"] or {}) do
      for _, machinePositionData in pairs(machineSurfaceData) do
        for _, machineData in pairs(machinePositionData) do
          if machineData.direction ~= nil and oldToNewDirection[machineData.direction] ~= nil then
            machineData.direction = oldToNewDirection[machineData.direction]
          end
          if machineData.entity and machineData.entity.valid and machineData.renderID then
            for _, animationLayer in pairs{"base", "overlay"} do
              compat.set_render_animation(machineData.renderID[animationLayer], machineData.entity.name .. "-" .. FLib.utils.directions.toString(machineData.direction or machineData.entity.direction) .. "-" .. animationLayer)
            end
          end
        end
      end
    end
    storage.TA_data.version = 6
  end

  if storage.TA_data.version == 6 then
    log("Updating Trainassembly from version 6 to version 7 (blueprintable protected rails).")
    for _, machineSurfaceData in pairs(storage.TA_data and storage.TA_data["trainAssemblers"] or {}) do
      for _, machinePositionData in pairs(machineSurfaceData) do
        for _, machineData in pairs(machinePositionData) do
          local machineEntity = machineData.entity
          if machineEntity and machineEntity.valid then
            for _, railEntity in pairs(machineEntity.surface.find_entities_filtered{
              name = "straight-rail",
              type = "straight-rail",
              area = {
                {machineEntity.position.x - 3.1, machineEntity.position.y - 3.1},
                {machineEntity.position.x + 3.1, machineEntity.position.y + 3.1},
              },
            }) do
              railEntity.destructible = false
              railEntity.minable_flag = true -- keep rails selectable/blueprintable
            end
          end
        end
      end
    end
    storage.TA_data.version = 7
  end

  if storage.TA_data.version == 7 then
    log("Updating Trainassembly from version 7 to version 8 (quality support).")
    for _, machineSurfaceData in pairs(storage.TA_data and storage.TA_data["trainAssemblers"] or {}) do
      for _, machinePositionData in pairs(machineSurfaceData) do
        for _, machineData in pairs(machinePositionData) do
          machineData.pendingQuality = machineData.pendingQuality or "normal"
        end
      end
    end
    storage.TA_data.version = 8
  end


end
