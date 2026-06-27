---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
require("compat.lslib")
local compat = require("compat.factorio_2")

-- To make sure everything is inline with the technology tree when the mod is added.
-- This is for when the mod is added into an existing game or when the mod is updated.
local trainControllerGui = require("prototypes.gui.layout.traincontroller")
local trainDepotGui = require("prototypes.gui.layout.traindepot")

require("src.traincontroller")
require("src.traindepot")

return function(configurationData)
  local modChanges = configurationData.mod_changes["trainConstructionSiteFork"] or configurationData.mod_changes["trainConstructionSite"]
  if modChanges and modChanges.new_version ~= (modChanges.old_version or "") then
    log(string.format("Updating trainConstructionSiteFork from version %q to version %q", modChanges.old_version or "nil", modChanges.new_version))

    --------------------------------------------------
    -- Prototype data                               --
    --------------------------------------------------
    for forceName, force in pairs(game.forces) do
      local technologies = force.technologies
      local recipes      = force.recipes

      if recipes["locomotive"].enabled then
        technologies["trainassembly-automated-train-assembling"].researched = true
      end

      if recipes["cargo-wagon"].enabled then
        technologies["trainassembly-cargo-wagon"].researched = true
     end

      if recipes["artillery-wagon"].enabled then
        technologies["trainassembly-artillery-wagon"].researched = true
      end

      force.reset_technology_effects()
    end

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


    --------------------------------------------------
    -- Traincontroller script                       --
    --------------------------------------------------
    if storage.TC_data.version == 1 then
      log("Updating Traincontroller from version 1 to version 2.")
      if FLib.utils.table.isEmpty(storage.TC_data["trainControllers"]) and storage.TC_data["nextTrainControllerIterate"] then
        storage.TC_data["nextTrainControllerIterate"] = nil
        Traincontroller.Builder:deactivateOnTick()
      end
      storage.TC_data.version = 2
    end

    if storage.TC_data.version == 2 then
      log("Updating Traincontroller from version 2 to version 3.")
      for surfaceIndex, surfaceData in pairs(storage.TC_data["trainControllers"] or {}) do
        for controllerPositionY, controllerPositionData in pairs(surfaceData) do
          for controllerPositionX, controllerData in pairs(controllerPositionData) do
            for _, hiddenEntity in pairs(controllerData["entity-hidden"]) do
              if hiddenEntity.valid then
                hiddenEntity.destroy()
              end
            end
            controllerData["entity-hidden"] = {}
            local controllerEntity = controllerData["entity"]
            for hiddenEntityIndex, hiddenEntityData in pairs(Traincontroller:getHiddenEntityData(controllerEntity.position, controllerEntity.direction)) do
              controllerData["entity-hidden"][hiddenEntityIndex] = controllerEntity.surface.create_entity{
                name      = hiddenEntityData.name,
                position  = hiddenEntityData.position,
                direction = hiddenEntityData.direction,
                force     = Traincontroller:getDepotForceName(controllerEntity.force.name)
              }
            end
            if storage.TA_data["trainBuilders"][controllerData.trainBuilderIndex] then
            else
              local controllerEntity = controllerData.entity
              if controllerEntity and controllerEntity.valid then
                local createdEntityForceName = storage.TC_data["trainControllerForces"][controllerEntity.force.name] or controllerEntity.force.name
                local entityDirection = controllerEntity.direction
                local entitySearchDirection = {
                  x = (entityDirection == defines.direction.west  and 1 or 0) + (entityDirection == defines.direction.east  and -1 or 0),
                  y = (entityDirection == defines.direction.north and 1 or 0) + (entityDirection == defines.direction.south and -1 or 0),
                }
                local entityPosition = controllerEntity.position
                local newBuilderIndex = Trainassembly:getTrainBuilderIndex(controllerData.entity.surface.find_entities_filtered{
                  name     = Trainassembly:getMachineEntityName(),
                  force    = createdEntityForceName,
                  area     = {
                    { entityPosition.x + 3.5*entitySearchDirection.x - 1.5*entitySearchDirection.y , entityPosition.y + 3.5*entitySearchDirection.y + 1.5*entitySearchDirection.x },
                    { entityPosition.x + 5.5*entitySearchDirection.x - 2.5*entitySearchDirection.y , entityPosition.y + 5.5*entitySearchDirection.y + 2.5*entitySearchDirection.x },
                  },
                  limit    = 1,
                }[1])
                if newBuilderIndex == controllerData.trainBuilderIndex then
                  Traincontroller:onTrainbuilderAltered(controllerData.trainBuilderIndex)
                else
                  controllerData.trainBuilderIndex = newBuilderIndex
                end
              end
            end
            local builderStates = Traincontroller.Builder:initGlobalData()["builderStates"]
            if controllerData["controllerStatus"] == builderStates["idle"] or
               controllerData["controllerStatus"] == builderStates["dispatch"] then
              if Traincontroller.Builder:getBuildTrain(controllerData.trainBuilderIndex) then
              else
                controllerData["controllerStatus"] = builderStates["building"]
              end
            end
          end
        end
      end
      storage.TC_data.version = 3
    end

    if storage.TC_data.version == 3 then
      log("Updating Traincontroller from version 3 to version 4.")
      storage.TC_data["pendingControllers"] = storage.TC_data["pendingControllers"] or {}
      for _, surface in pairs(game.surfaces) do
        for _, signal in pairs(surface.find_entities_filtered{name = Traincontroller:getControllerSignalEntityName()}) do
          if signal and signal.valid then signal.destroy() end
        end
      end
      for _, surfaceData in pairs(storage.TC_data["trainControllers"] or {}) do
        for _, positionYData in pairs(surfaceData) do
          for _, controllerData in pairs(positionYData) do
            for hiddenEntityIndex, hiddenEntity in pairs(controllerData["entity-hidden"] or {}) do
              if hiddenEntity and hiddenEntity.valid and hiddenEntity.name == Traincontroller:getControllerSignalEntityName() then
                hiddenEntity.destroy()
                controllerData["entity-hidden"][hiddenEntityIndex] = nil
              end
            end
          end
        end
      end
      storage.TC_data.version = 4
      Traincontroller:syncPendingControllerTick()
    end


    --------------------------------------------------
    -- Traincontroller.Gui script                   --
    --------------------------------------------------
    if storage.TC_data.Gui.version == 1 then
      log("Updating Traincontroller.Gui from version 1 to version 2.")
      storage.TC_data.Gui["prototypeData"]["trainControllerGui"] = trainControllerGui
      storage.TC_data.Gui.version = 2
    end

    if storage.TC_data.Gui.version == 2 then
      log("Updating Traincontroller.Gui from version 2 to version 3.")
      storage.TC_data.Gui["clickHandler"] = nil
      storage.TC_data.Gui.version = 3
    end

    if storage.TC_data.Gui.version == 3 then
      log("Updating Traincontroller.Gui from version 3 to version 4.")
      storage.TC_data.Gui["prototypeData"]["trainControllerGui"] = trainControllerGui
      storage.TC_data.Gui.version = 4
    end

    if storage.TC_data.Gui.version == 4 then
      log("Updating Traincontroller.Gui from version 4 to version 5.")
      for playerIndex, _ in pairs(game.players) do
        if Traincontroller.Gui:hasOpenedGui(playerIndex) then
          game.players[playerIndex].opened = Traincontroller.Gui:destroyGui(playerIndex)
          Traincontroller.Gui:setOpenedControllerEntity(playerIndex, nil)
        end
      end
      storage.TC_data.Gui["prototypeData"] = Traincontroller.Gui:initPrototypeData()
      storage.TC_data.Gui.version = 5
    end

    if storage.TC_data.Gui.version == 5 then
      log("Updating Traincontroller.Gui from version 5 to version 6.")
      for playerIndex, _ in pairs(game.players) do
        if Traincontroller.Gui:hasOpenedGui(playerIndex) then
          game.players[playerIndex].opened = Traincontroller.Gui:destroyGui(playerIndex)
          Traincontroller.Gui:setOpenedControllerEntity(playerIndex, nil)
        end
      end
      storage.TC_data.Gui["prototypeData"] = Traincontroller.Gui:initPrototypeData()
      storage.TC_data.Gui.version = 6
    end

    if storage.TC_data.Gui.version == 6 then
      log("Updating Traincontroller.Gui from version 6 to version 7.")
      for playerIndex, _ in pairs(game.players) do
        if Traincontroller.Gui:hasOpenedGui(playerIndex) then
          game.players[playerIndex].opened = Traincontroller.Gui:destroyGui(playerIndex)
          Traincontroller.Gui:setOpenedControllerEntity(playerIndex, nil)
        end
      end
      storage.TC_data.Gui["prototypeData"] = Traincontroller.Gui:initPrototypeData()
      storage.TC_data.Gui.version = 7
    end

    if storage.TC_data.Gui.version == 7 then
      log("Updating Traincontroller.Gui from version 7 to version 8.")
      for playerIndex, _ in pairs(game.players) do
        if Traincontroller.Gui:hasOpenedGui(playerIndex) then
          game.players[playerIndex].opened = Traincontroller.Gui:destroyGui(playerIndex)
          Traincontroller.Gui:setOpenedControllerEntity(playerIndex, nil)
        end
      end
      storage.TC_data.Gui["prototypeData"] = Traincontroller.Gui:initPrototypeData()
      storage.TC_data.Gui.version = 8
    end


    --------------------------------------------------
    -- Traindepot script                            --
    --------------------------------------------------
    if storage.TD_data.version == 1 then
      log("Updating Traindepot from version 1 to version 2.")
      storage.TD_data.version = 2
    end

    if storage.TD_data.version == 2 then 
      log("Updating Traindepot from version 2 to version 3.")
      for depotSurfaceIndex, depotSurfaceData in pairs(storage.TD_data["depots"]) do 
        for depotPositionY,depotPositionList in pairs(depotSurfaceData) do
          for depotPositionX,depotEntityData in pairs(depotPositionList) do
            local depotEntity = depotEntityData.entity
            if depotEntity.valid then
            else
              local foundEntity = game.get_surface(depotSurfaceIndex).find_entities_filtered {
                type = "train-stop",
                name = Traindepot:getDepotEntityName(),
                position = {x = depotPositionX, y = depotPositionY},
                radius = 1,
                limit = 1,
              }[1]
              if foundEntity then
                storage.TD_data["depots"][depotSurfaceIndex][depotPositionX][depotPositionY].entity = foundEntity
              else
                if storage.TD_data["depots"][depotSurfaceIndex][depotPositionY][depotPositionX] then
                  storage.TD_data["depots"][depotSurfaceIndex][depotPositionY][depotPositionX] = nil

                  if FLib.utils.table.isEmpty(storage.TD_data["depots"][depotSurfaceIndex][depotPositionY]) then
                    storage.TD_data["depots"][depotSurfaceIndex][depotPositionY] = nil

                    if FLib.utils.table.isEmpty(storage.TD_data["depots"][depotSurfaceIndex]) then
                      storage.TD_data["depots"][depotSurfaceIndex] = nil
                    end
                  end
                end
              end
            end
          end
        end
      end
      storage.TD_data.version = 3
    end

    --------------------------------------------------
    -- Traindepot.Gui script                        --
    --------------------------------------------------
    if storage.TD_data.Gui.version == 1 then
      log("Updating Traindepot.Gui from version 1 to version 2.")
      storage.TD_data.Gui["prototypeData"]["trainDepotGui"] = trainDepotGui
      storage.TD_data.Gui.version = 2
    end

    if storage.TD_data.Gui.version == 2 then
      log("Updating Traindepot.Gui from version 2 to version 3.")
      storage.TD_data.Gui["clickHandler"] = nil
      storage.TD_data.Gui.version = 3
    end

    if storage.TD_data.Gui.version == 3 then
      log("Updating Traindepot.Gui from version 3 to version 4.")
      storage.TD_data.Gui["prototypeData"]["trainDepotGui"] = trainDepotGui
      storage.TD_data.Gui.version = 4
    end

    if storage.TD_data.Gui.version == 4 then
      log("Updating Traindepot.Gui from version 4 to version 5.")
      for playerIndex, _ in pairs(game.players) do 
        if Traindepot.Gui:hasOpenedGui(playerIndex) then
          Traindepot.Gui:setOpenedEntity(playerIndex, nil)
          game.players[playerIndex].opened = Traindepot.Gui:destroyGui(playerIndex)
        end
      end
      storage.TD_data.Gui["prototypeData"] = Traindepot.Gui:initPrototypeData()
      storage.TD_data.Gui.version = 5
    end

    if storage.TD_data.Gui.version == 5 then
      log("Updating Traindepot.Gui from version 5 to version 6.")
      for playerIndex, _ in pairs(game.players) do
        if Traindepot.Gui:hasOpenedGui(playerIndex) then
          game.players[playerIndex].opened = Traindepot.Gui:destroyGui(playerIndex)
          Traindepot.Gui:setOpenedEntity(playerIndex, nil)
        end
      end
      storage.TD_data.Gui["prototypeData"] = Traindepot.Gui:initPrototypeData()
      storage.TD_data.Gui.version = 6
    end

    if storage.TD_data.Gui.version == 6 then
      log("Updating Traindepot.Gui from version 6 to version 7.")
      for playerIndex, _ in pairs(game.players) do
        if Traindepot.Gui:hasOpenedGui(playerIndex) then
          game.players[playerIndex].opened = Traindepot.Gui:destroyGui(playerIndex)
          Traindepot.Gui:setOpenedEntity(playerIndex, nil)
        end
      end
      storage.TD_data.Gui["prototypeData"] = Traindepot.Gui:initPrototypeData()
      storage.TD_data.Gui.version = 7
    end

    if storage.TD_data.Gui.version == 7 then
      log("Updating Traindepot.Gui from version 7 to version 8.")
      for playerIndex, _ in pairs(game.players) do
        if Traindepot.Gui:hasOpenedGui(playerIndex) then
          game.players[playerIndex].opened = Traindepot.Gui:destroyGui(playerIndex)
          Traindepot.Gui:setOpenedEntity(playerIndex, nil)
        end
      end
      storage.TD_data.Gui["prototypeData"] = Traindepot.Gui:initPrototypeData()
      storage.TD_data.Gui.version = 8
    end


    --------------------------------------------------
    -- Help.Gui script                              --
    --------------------------------------------------
    if storage.H_data and storage.H_data.Gui then
      if storage.H_data.Gui.version then
        log("Removing Help.Gui version "..(storage.H_data.Gui.version or "unknown")..".")
      end
      for player_index, _ in pairs(game.players) do
        if storage.H_data.Gui["openedGui"][player_index] then
          storage.H_data.Gui["openedGui"][player_index].destroy()
        end
      end
      storage.H_data.Gui = nil
    end

    --------------------------------------------------
    -- Help script                                  --
    --------------------------------------------------
    if storage.H_data then
      if storage.H_data.version then
        log("Removing Help version "..(storage.H_data.version or "unknown")..".")
      end
      storage.H_data = nil
    end

  end
end
