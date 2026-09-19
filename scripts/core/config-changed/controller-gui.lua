---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Datenstand der Controller-GUI hochziehen.
-- Teil von on_configuration_changed, siehe init.lua.

local trainControllerGui = require("prototypes.gui.layout.traincontroller")

return function()
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


end
