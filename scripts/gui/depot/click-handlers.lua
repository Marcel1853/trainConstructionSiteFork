---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traindepot.Gui: Klick-Handler der Fenster-Elemente.

function Traindepot.Gui:initClickHandlers()
  local clickHandlers = {}

  ------------------------------------------------------------------------------
  -- help button handler
  ------------------------------------------------------------------------------
  clickHandlers["traindepot-help"] = function(clickedElement, playerIndex)
    -- close this UI
    Traindepot.Gui:setOpenedEntity(playerIndex, nil)
    game.players[playerIndex].opened = Traindepot.Gui:destroyGui(playerIndex)

    -- open the new UI
    --Help.Gui:openGui(playerIndex)
  end



  ------------------------------------------------------------------------------
  -- close button handler
  ------------------------------------------------------------------------------
  clickHandlers["traindepot-close"] = function(clickedElement, playerIndex)
    -- close this UI
    Traindepot.Gui:setOpenedEntity(playerIndex, nil)
    game.players[playerIndex].opened = Traindepot.Gui:destroyGui(playerIndex)
  end



  ------------------------------------------------------------------------------
  -- tab button handler
  ------------------------------------------------------------------------------
  local tabButtonHandler = function(clickedTabButton, playerIndex)
    -- Get the flow with all the buttons
    if clickedTabButton.type ~= "button" then return end -- clicked on content
    local tabButtonFlow = clickedTabButton.parent

    -- Get the flow with all the contents
    local tabContentFlow = tabButtonFlow.parent
    tabContentFlow = tabContentFlow[tabContentFlow.name .. "-content"]
    if not tabContentFlow then return end

    -- For each button in the flow, set the new style and set the tabs
    local clickedTabButtonName = clickedTabButton.name
    for _, tabButtonName in pairs {
      "traindepot-tab-selection",
      "traindepot-tab-statistics",
    } do
      tabButtonFlow[tabButtonName].style = (tabButtonName == clickedTabButtonName and "LSlib_default_tab_button_selected" or "LSlib_default_tab_button")
      tabContentFlow[tabButtonName].visible = (tabButtonName == clickedTabButtonName)
    end
  end

  for _, tabButtonName in pairs {
    "traindepot-tab-selection",
    "traindepot-tab-statistics",
  } do
    clickHandlers[tabButtonName] = tabButtonHandler
  end



  ------------------------------------------------------------------------------
  -- statistics
  ------------------------------------------------------------------------------
  clickHandlers["statistics-station-id-edit"] = function(clickedElement, playerIndex)
    local tabToOpen = "traindepot-tab-selection"
    Traindepot.Gui:getClickHandler(tabToOpen)(
    FLib.gui.getElement(playerIndex, Traindepot.Gui:getTabElementPath(tabToOpen)), playerIndex)                                           -- mimic tab pressed
  end

  clickHandlers["statistics-builder-amount-value-"] = function(clickedElement, playerIndex)
    local depotEntity       = Traindepot.Gui:getOpenedEntity(playerIndex)
    local depotForceName    = depotEntity.force.name
    local depotSurfaceIndex = depotEntity.surface.index
    local depotName         = depotEntity.backer_name

    -- update the data
    Traindepot:setDepotRequestCount(depotForceName, depotSurfaceIndex, depotName,
      Traindepot:getDepotRequestCount(depotForceName, depotSurfaceIndex, depotName) - 1)

    -- update the gui element
    FLib.gui.getElement(playerIndex, Traindepot.Gui:getUpdateElementPath("statistics-builder-amount-value")).caption =
    string.format("%i/%i",
      Traindepot:getDepotRequestCount(depotForceName, depotSurfaceIndex, depotName),
      Traindepot:getDepotStationCount(depotForceName, depotSurfaceIndex, depotName))
  end

  clickHandlers["statistics-builder-amount-value+"] = function(clickedElement, playerIndex)
    local depotEntity       = Traindepot.Gui:getOpenedEntity(playerIndex)
    local depotForceName    = depotEntity.force.name
    local depotSurfaceIndex = depotEntity.surface.index
    local depotName         = depotEntity.backer_name

    -- update the data
    Traindepot:setDepotRequestCount(depotForceName, depotSurfaceIndex, depotName,
      Traindepot:getDepotRequestCount(depotForceName, depotSurfaceIndex, depotName) + 1)

    -- update the gui element
    FLib.gui.getElement(playerIndex, Traindepot.Gui:getUpdateElementPath("statistics-builder-amount-value")).caption =
    string.format("%i/%i",
      Traindepot:getDepotRequestCount(depotForceName, depotSurfaceIndex, depotName),
      Traindepot:getDepotStationCount(depotForceName, depotSurfaceIndex, depotName))
  end

  clickHandlers["statistics-builder-list-button"] = function(clickedElement, playerIndex)
    local minimapElement   = clickedElement["statistics-builder-list-minimap"]
    local controllerEntity = game.surfaces[minimapElement.surface_index].find_entities_filtered {
      name     = Traincontroller:getControllerEntityName(),
      position = minimapElement.position,
      limit    = 1,
    }[1]
    if controllerEntity then
      -- destroy this depot UI
      Traindepot.Gui:onCloseEntity(game.players[playerIndex].opened, playerIndex)

      -- open the controller UI
      Traincontroller.Gui:onOpenEntity(controllerEntity, playerIndex)
    end
  end



  ------------------------------------------------------------------------------
  -- select train depot name
  ------------------------------------------------------------------------------
  clickHandlers["selected-depot-list"] = function(clickedElement, playerIndex)
    local listboxElement = FLib.gui.getElement(playerIndex, Traindepot.Gui:getUpdateElementPath("selected-depot-list"))

    FLib.gui.getElement(playerIndex, Traindepot.Gui:getUpdateElementPath("selected-depot-name")).text = listboxElement
    .get_item(listboxElement.selected_index)
  end

  clickHandlers["selected-depot-enter"] = function(clickedElement, playerIndex)
    local depotEntity  = Traindepot.Gui:getOpenedEntity(playerIndex)
    local oldDepotName = depotEntity.backer_name
    local newDepotName = FLib.gui.getElement(playerIndex, Traindepot.Gui:getUpdateElementPath("selected-depot-name"))
    .text

    if newDepotName ~= oldDepotName then
      depotEntity.backer_name = newDepotName -- invokes the rename event which will update UI's
      --Traindepot.Gui:updateGuiInfo(playerIndex)
    end

    -- mimic tab pressed to go back to statistics tab
    local tabToOpen = "traindepot-tab-statistics"
    Traindepot.Gui:getClickHandler(tabToOpen)(
    FLib.gui.getElement(playerIndex, Traindepot.Gui:getTabElementPath(tabToOpen)), playerIndex)
  end



  ------------------------------------------------------------------------------
  return clickHandlers
end

Traindepot.Gui.clickHandlers = Traindepot.Gui:initClickHandlers()
