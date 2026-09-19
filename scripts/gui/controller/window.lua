---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller.Gui: Fenster öffnen, schließen, aktualisieren und GUI-Ereignisse.

local trainRecipe = require("compat.train_recipe")

--------------------------------------------------------------------------------
-- Gui functions
--------------------------------------------------------------------------------
function Traincontroller.Gui:createGui(playerIndex)
  -- Refresh cached layout data so saves created with older port builds don't keep
  -- removed Factorio 2.0 utility sprites such as utility/close_white.
  storage.TC_data.Gui["prototypeData"] = self:initPrototypeData()
  local trainDepoGui = FLib.gui.create(playerIndex, self:getControllerGuiLayout())
  self:updateGuiInfo(playerIndex)
  return trainDepoGui
end



function Traincontroller.Gui:destroyGui(playerIndex)
  -- make sure the color picker is closed first
  local colorPickerElement = FLib.gui.getElement(playerIndex, self:getUpdateElementPath("traincontroller-color-picker"))
  if colorPickerElement and colorPickerElement.visible then
    -- simulate clicking discard
    self:getClickHandler("traincontroller-color-picker-button-discard")(nil, playerIndex)
  end
  return FLib.gui.destroy(playerIndex, self:getControllerGuiLayout())
end



function Traincontroller.Gui:updateGuiInfo(playerIndex)
  -- We expect the gui to be created already
  local trainDepotGui = FLib.gui.getElement(playerIndex, FLib.gui.layout.getElementPath(self:getControllerGuiLayout(), self:getGuiName()))
  if not trainDepotGui then return end -- gui was not created, nothing to update

  -- data from the traindepo we require to update
  local openedEntity           = self:getOpenedControllerEntity(playerIndex)
  if not (openedEntity and openedEntity.valid) then
    self:onCloseEntity(trainDepotGui, playerIndex)
  end

  local controllerName         = (openedEntity and openedEntity.backer_name) or ""
  local controllerForceName    = (openedEntity and openedEntity.force and openedEntity.force.name) or ""
  local controllerSurfaceIndex = (openedEntity and openedEntity.surface and openedEntity.surface.index) or (game.get_player(playerIndex) and game.get_player(playerIndex).surface and game.get_player(playerIndex).surface.index) or 1
  local controllerDirection    = (openedEntity and openedEntity.direction) or defines.direction.north

  local depotForceName    = Traincontroller:getDepotForceName(controllerForceName)
  local depotRequestCount = Traindepot:getDepotRequestCount(depotForceName, controllerSurfaceIndex, controllerName)
  local depotTrainCount   = Traindepot:getNumberOfTrainsPathingToDepot(controllerSurfaceIndex, controllerName)

  local trainBuilder         = Trainassembly:getTrainBuilder(Traincontroller:getTrainBuilderIndex(openedEntity))
  local trainBuilderIterator = Trainassembly:getTrainBuilderIterator(controllerDirection)

  -- statistics ----------------------------------------------------------------
  -- controller depot name
  FLib.gui.getElement(playerIndex, self:getUpdateElementPath("statistics-station-id-value")).caption = controllerName

  -- requested amount of trains in depot
  FLib.gui.getElement(playerIndex, self:getUpdateElementPath("statistics-depot-request-value")).caption = string.format(
    "%i/%i", depotTrainCount, depotRequestCount)

  -- status of the builder
  FLib.gui.getElement(playerIndex, self:getUpdateElementPath("statistics-builder-status-value")).caption = self:getOpenedControllerStatusString(playerIndex)

  -- configuration
  local configurationElement = FLib.gui.getElement(playerIndex, self:getUpdateElementPath("statistics-builder-configuration-flow"))

  local colorPickerSelectedIndex -- extract the selected element first, required for the color picker
  local configurationElementCount = #configurationElement.children_names
  local colorPickerFrame = FLib.gui.getElement(playerIndex, self:getUpdateElementPath("traincontroller-color-picker"))
  local clickedElementStyle        = "traincontroller_color_indicator_button_housing"
  local clickedElementPressedStyle = clickedElementStyle.."_pressed"

  if colorPickerFrame.visible then
    for _, assemblerElementIndex in pairs(configurationElement.children_names) do
      local colorElement = configurationElement[assemblerElementIndex]["statistics-builder-configuration-button-color"]
      if colorElement and colorElement.style.name == clickedElementPressedStyle then
        -- found the selected one
        colorPickerSelectedIndex = assemblerElementIndex

        break -- no need to look further
      end
    end
  end

  configurationElement.clear()
  configurationElement.add{
    type      = "flow",
    name      = "0-traincontroller",
    direction = "vertical",
    style     = "traincontroller_configuration_flow",
  }.add{
    type    = "sprite-button",
    name    = "statistics-builder-configuration-button-recipe",
    tooltip = {"item-name.traincontroller", {"item-name.trainassembly"}},
    sprite  = string.format("item/%s", Traincontroller:getControllerItemName()),
    enabled = false,
  }
  for trainAssemblerIndex,trainAssemblerLocation in trainBuilderIterator(trainBuilder) do
    local trainAssembler = Trainassembly:getMachineEntity(trainAssemblerLocation.surfaceIndex, trainAssemblerLocation.position)
    if trainAssembler and trainAssembler.valid then
      local flow = configurationElement.add{
        type      = "flow",
        name      = string.format("%i", trainAssemblerIndex),
        direction = "vertical",
        style     = "traincontroller_configuration_flow",
      }

      local trainAssemblerRecipe = trainAssembler.get_recipe()
      if trainAssemblerRecipe then
        flow.add{
          type   = "sprite-button",
          name   = "statistics-builder-configuration-button-recipe",
          sprite = string.format("fluid/%s", trainAssemblerRecipe.products[1].name),
        }

        local _, trainAssemblyType = trainRecipe.parse_name(trainAssemblerRecipe.name)
        if trainAssemblyType == "locomotive"      or
           trainAssemblyType == "artillery-wagon" then
          flow.add{
            type    = "sprite-button",
            name    = "statistics-builder-configuration-button-rotate",
            tooltip = {"controls.rotate"},
            sprite  = string.format("traincontroller-orientation-%s", trainAssembler.direction == controllerDirection and "L" or "R"),
          }

          if trainAssemblyType == "locomotive" then
            flow.add{
              type    = "button",
              name    = "statistics-builder-configuration-button-color",
              tooltip = {"gui-train.color"},
              style   = "traincontroller_color_indicator_button_housing",
            }.add{
              type  = "progressbar",
              name  = "statistics-builder-configuration-button-color",
              value = 1,
              style = "traincontroller_color_indicator_button_color",
              ignored_by_interaction = true,
            }.add{
              type   = "sprite-button",
              name   = "statistics-builder-configuration-button-color",
              sprite = "utility/color_picker",
              style  = "traincontroller_color_indicator_button_sprite",
              ignored_by_interaction = true,
            }.parent.style.color = Trainassembly:getMachineTint(trainAssembler)
          end
        end
      end

    end
  end



  -- select depot name ---------------------------------------------------------
  FLib.gui.getElement(playerIndex, self:getUpdateElementPath("selected-depot-name")).caption = controllerName

  -- name selection list
  local depotEntriesList = FLib.gui.getElement(playerIndex, self:getUpdateElementPath("selected-depot-list"))
  depotEntriesList.clear_items()

  local itemIndex = 1
  local orderedPairs = FLib.utils.table.orderedPairs
  for trainDepotName,_ in orderedPairs(Traindepot:getDepotData(depotForceName, controllerSurfaceIndex)) do
    -- https://lua-api.factorio.com/latest/LuaGuiElement.html#LuaGuiElement.add_item
    depotEntriesList.add_item(trainDepotName)
    if trainDepotName == controllerName then
      depotEntriesList.selected_index = itemIndex
    end
    itemIndex = itemIndex + 1
  end

  -- color picker --------------------------------------------------------------
  if colorPickerFrame.visible then
    -- set the button to selected again, else we close the UI
    local colorPickerFrameValid = true
    if colorPickerSelectedIndex and configurationElementCount == #configurationElement.children_names then
      -- still the same amount of children, make sure the recipe is still the same
      local colorElement = configurationElement[string.format("%i", colorPickerSelectedIndex)]["statistics-builder-configuration-button-color"]
      if colorElement then
        -- set it selected again
        colorElement.style = clickedElementPressedStyle

        -- and we update the color
        local buttonColor = {}
        local colorName = "traincontroller-color-picker-%s"
        for _, colorIndex in pairs{"r", "g", "b"} do
          buttonColor[colorIndex] = math.floor(.5 + colorPickerFrame[string.format(colorName, "flow-"..colorIndex)][string.format(colorName, "slider")].slider_value)
        end
        colorElement[colorElement.name].style.color = buttonColor

      else
        -- no picker element anymore, close the UI
        colorPickerFrameValid = false
      end
    else -- no selected index found, or something got removed, we remove the picker
      colorPickerFrameValid = false
    end

    if not colorPickerFrameValid then
      -- close the UI as it is not needed anymore, simulate clicking discard
      self:getClickHandler("traincontroller-color-picker-button-discard")(nil, playerIndex)
    end

  end

end



function Traincontroller.Gui:updateOpenedGuis(updatedControllerEntity, upgradeDepots)

  for _,player in pairs(game.connected_players) do -- no need to check all players
    local openedEntity = self:getOpenedControllerEntity(player.index)
    if openedEntity then
      if openedEntity.valid and openedEntity.health > 0 then
        if openedEntity == updatedControllerEntity then
          self:updateGuiInfo(player.index)
        end
      else -- not valid/killed
        self:onCloseEntity(player.opened, player.index)
      end
    end
  end

  if upgradeDepots ~= false then upgradeDepots = true end
  if upgradeDepots and updatedControllerEntity.valid then
    Traindepot.Gui:updateOpenedGuis(updatedControllerEntity.backer_name)
  end
end



--------------------------------------------------------------------------------
-- Behaviour functions, mostly event handlers
--------------------------------------------------------------------------------
-- When a player opens a gui
function Traincontroller.Gui:onOpenEntity(openedEntity, playerIndex)
  if openedEntity and openedEntity.name == Traincontroller:getControllerEntityName() then
    self:setOpenedControllerEntity(playerIndex, openedEntity)
    game.players[playerIndex].opened = self:createGui(playerIndex)
  end
end



-- When a player opens/closes a gui
function Traincontroller.Gui:onCloseEntity(openedGui, playerIndex)
  if openedGui and openedGui.valid then
    if openedGui.name == self:getGuiName() then
      game.players[playerIndex].opened = self:destroyGui(playerIndex)
      self:setOpenedControllerEntity(playerIndex, nil)

    elseif openedGui.name == self:getRecipeSelectorEntityName() then
      -- TODO... at some point if I can get it working
    end
  end
end



-- When a player clicks on the gui
function Traincontroller.Gui:onClickElement(clickedElement, playerIndex)
  if self:hasOpenedGui(playerIndex) then
    if not clickedElement.valid then return end
    local clickHandler = self:getClickHandler(clickedElement.name)
    if clickHandler then clickHandler(clickedElement, playerIndex) end
  end
end



function Traincontroller.Gui:onPlayerCreated(playerIndex)
  -- Called after the player was created.
  self:initEntityPreviewPlayer(playerIndex)
end



function Traincontroller.Gui:onPlayerLeftGame(playerIndex)
  -- Called after a player leaves the game.
  if self:hasOpenedGui(playerIndex) then
    self:onCloseEntity(game.players[playerIndex].opened, playerIndex)
  end
end
