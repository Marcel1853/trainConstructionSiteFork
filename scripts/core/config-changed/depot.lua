---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Datenstand von Traindepot und Depot-GUI (storage.TD_data) hochziehen.
-- Teil von on_configuration_changed, siehe init.lua.

local trainDepotGui = require("prototypes.gui.layout.traindepot")

return function()
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


end
