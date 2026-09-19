---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller.Gui: Klick-Handler der Fenster-Elemente.

function Traincontroller.Gui:initClickHandlers()
  local clickHandlers = {}

  ------------------------------------------------------------------------------
  -- help button handler
  ------------------------------------------------------------------------------
  clickHandlers["traincontroller-help"] = function(clickedElement, playerIndex)
    -- close this UI
    game.players[playerIndex].opened = Traincontroller.Gui:destroyGui(playerIndex)
    Traincontroller.Gui:setOpenedControllerEntity(playerIndex, nil)

    -- open the new UI
    --Help.Gui:openGui(playerIndex)
  end



  ------------------------------------------------------------------------------
  -- close button handler
  ------------------------------------------------------------------------------
  clickHandlers["traincontroller-close"] = function(clickedElement, playerIndex)
    -- close this UI
    game.players[playerIndex].opened = Traincontroller.Gui:destroyGui(playerIndex)
    Traincontroller.Gui:setOpenedControllerEntity(playerIndex, nil)
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
    for _,tabButtonName in pairs{
      "traincontroller-tab-selection" ,
      "traincontroller-tab-statistics",
    } do
      tabButtonFlow[tabButtonName].style = (tabButtonName == clickedTabButtonName and "LSlib_default_tab_button_selected" or "LSlib_default_tab_button")
      tabContentFlow[tabButtonName].visible = (tabButtonName == clickedTabButtonName)
    end
  end

  for _,tabButtonName in pairs{
    "traincontroller-tab-selection" ,
    "traincontroller-tab-statistics",
  } do
    clickHandlers[tabButtonName] = tabButtonHandler
  end



  ------------------------------------------------------------------------------
  -- statistics
  ------------------------------------------------------------------------------
  clickHandlers["statistics-station-id-edit"] = function(clickedElement, playerIndex)
    local tabToOpen = "traincontroller-tab-selection"
    Traincontroller.Gui:getClickHandler(tabToOpen)(FLib.gui.getElement(playerIndex, Traincontroller.Gui:getTabElementPath(tabToOpen)), playerIndex) -- mimic tab pressed
  end



  --[[clickHandlers["statistics-builder-configuration-button-recipe"] = function(clickedElement, playerIndex)
    local player = game.get_player(playerIndex)
    local recipeEntity =  player.surface.create_entity{
      name     = Traincontroller.Gui:getRecipeSelectorEntityName(),
      position = player.position,
      force    = player.force,
    }
    Traincontroller.Gui:setOpenedRecipeEntity(playerIndex, recipeEntity)
    player.opened = recipeEntity
  end]]



  clickHandlers["statistics-builder-configuration-button-rotate"] = function(clickedElement, playerIndex)
    -- get the trainbuilder
    local trainBuilder = Trainassembly:getTrainBuilder(Traincontroller:getTrainBuilderIndex(Traincontroller.Gui:getOpenedControllerEntity(playerIndex)))
    if not trainBuilder then return end

    -- get the assembler
    local trainAssemblerLocation = trainBuilder[tonumber(clickedElement.parent.name)]
    local trainAssembler = Trainassembly:getMachineEntity(trainAssemblerLocation.surfaceIndex, trainAssemblerLocation.position)
    if not (trainAssembler and trainAssembler.valid) then return end

    -- rotate the assembler
    local previous_direction = trainAssembler.direction
    trainAssembler.rotate()
    script.raise_event(Traincontroller.Gui:getRotateEventID(), {
      entity = trainAssembler,
      previous_direction = previous_direction,
      player_index = playerIndex
    })
  end



  clickHandlers["statistics-builder-configuration-button-color"] = function(clickedElement, playerIndex)
    local clickedElementStyle = "traincontroller_color_indicator_button_housing"
    local colorPickerFrame = FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("traincontroller-color-picker"))

    if clickedElement.style.name == clickedElementStyle then
      if colorPickerFrame.visible then
        -- another picker is open, we simulate clicking the discard button
        Traincontroller.Gui:getClickHandler("traincontroller-color-picker-button-discard")(clickedElement, playerIndex)
      end

      -- set the button as selected
      clickedElement.style = clickedElement.style.name .. "_pressed"

      -- set the color picker ui visible
      colorPickerFrame.visible = true

      -- set the colorPicker to the currently active color
      local color = clickedElement[clickedElement.name].style.color or {}
      local colorName = "traincontroller-color-picker-%s"
      for _, colorIndex in pairs{"r", "g", "b"} do
        local colorPickerIndexFrame = colorPickerFrame[string.format(colorName, "flow-"..colorIndex)]
        local colorPickerIndexValue = math.floor(.5 + (color[colorIndex] or 0) * 255)
        colorPickerIndexFrame[string.format(colorName, "slider"   )].slider_value = colorPickerIndexValue
        colorPickerIndexFrame[string.format(colorName, "textfield")].text         = ""..colorPickerIndexValue
      end

      -- set the entity-preview entity
      local entityRadius = 10
      local entityPreviewEntity = game.surfaces[Traincontroller.Gui:getControllerSurfaceName()].create_entity{
        name      = string.sub(clickedElement.parent["statistics-builder-configuration-button-recipe"].sprite, 7, -7),
        position  = {x = 3*entityRadius*playerIndex,
                     y = 0                         },
        direction = defines.direction.east,
        force     = game.get_player(playerIndex).force,
        player    = playerIndex,
      }
      if entityPreviewEntity then
        entityPreviewEntity.get_fuel_inventory().insert{
          name = "trainassembly-trainfuel",
          count = 1
        }
        entityPreviewEntity.color = {r=color.r, g=color.g, b=color.b, a = 127/255}

        local previewElement = FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("traincontroller-color-picker-entity-preview"))
        previewElement.entity = entityPreviewEntity
      else
        game.print(string.format("entity preview for %q could not be added at position {%i, %i}",
          string.sub(clickedElement.parent["statistics-builder-configuration-button-recipe"].sprite, 7, -7),
          3*entityRadius*playerIndex, 0
        ))
      end
    else
      -- simulate clicking the discard button
      Traincontroller.Gui:getClickHandler("traincontroller-color-picker-button-discard")(clickedElement, playerIndex)
    end
  end



  ------------------------------------------------------------------------------
  -- color pickers
  ------------------------------------------------------------------------------
  clickHandlers["traincontroller-color-picker-button-discard"] = function(clickedElement, playerIndex)

    -- STEP 1: set color picker hidden
    FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("traincontroller-color-picker")).visible = false

    -- also remove the entity-preview entity
    local entityRadius = 10
    local entity = game.surfaces[Traincontroller.Gui:getControllerSurfaceName()].find_entities_filtered{
      name      = "straight-rail",
      invert    = true,
      position  = {x = 3*entityRadius*playerIndex,
                   y = 0                         },
      radius    = entityRadius,
      limit     = 1,
    }[1]
    if entity then
      entity.destroy()
    end

    -- STEP 2: find the selected one
    local clickedElementStyle        = "traincontroller_color_indicator_button_housing"
    local clickedElementPressedStyle = clickedElementStyle.."_pressed"
    local configurationElement = FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("statistics-builder-configuration-flow"))

    for _, assemblerElementIndex in pairs(configurationElement.children_names) do
      local colorElement = configurationElement[assemblerElementIndex]["statistics-builder-configuration-button-color"]
      if colorElement and colorElement.style.name == clickedElementPressedStyle then
        -- found the selected one

        -- STEP 3: reset the color button
        colorElement.style = clickedElementStyle

        local trainBuilder = Trainassembly:getTrainBuilder(Traincontroller:getTrainBuilderIndex(Traincontroller.Gui:getOpenedControllerEntity(playerIndex)))
        if trainBuilder then
          local trainAssemblerLocation = trainBuilder[tonumber(assemblerElementIndex)]
          colorElement[colorElement.name].style.color = Trainassembly:getMachineTint(Trainassembly:getMachineEntity(trainAssemblerLocation.surfaceIndex, trainAssemblerLocation.position))
        end

        break -- no need to look further
      end
    end
  end



  clickHandlers["traincontroller-color-picker-button-confirm"] = function(clickedElement, playerIndex)

    -- STEP 1: set color picker hidden
    FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("traincontroller-color-picker")).visible = false

    -- also remove the entity-preview entity
    local entityRadius = 10
    game.surfaces[Traincontroller.Gui:getControllerSurfaceName()].find_entities_filtered{
      name      = "straight-rail",
      invert    = true,
      position  = {x = 3*entityRadius*playerIndex,
                   y = 0                         },
      radius    = entityRadius,
      limit     = 1,
    }[1].destroy()

    -- STEP 2: find the selected one
    local clickedElementStyle        = "traincontroller_color_indicator_button_housing"
    local clickedElementPressedStyle = clickedElementStyle.."_pressed"
    local configurationElement = FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("statistics-builder-configuration-flow"))

    for _, assemblerElementIndex in pairs(configurationElement.children_names) do
      local colorElement = configurationElement[assemblerElementIndex]["statistics-builder-configuration-button-color"]
      if colorElement and colorElement.style.name == clickedElementPressedStyle then
        -- found the selected one

        -- STEP 3: reset the color button
        colorElement.style = clickedElementStyle

        -- STEP 4: save the machine tint
        local controllerEntity = Traincontroller.Gui:getOpenedControllerEntity(playerIndex)
        local trainAssemblerLocation = (Trainassembly:getTrainBuilder(Traincontroller:getTrainBuilderIndex(controllerEntity)) or {})[tonumber(assemblerElementIndex)]
        if not trainAssemblerLocation then return end -- builder changed while the window was open
        local trainAssemblerEntity = Trainassembly:getMachineEntity(trainAssemblerLocation.surfaceIndex, trainAssemblerLocation.position)
        Trainassembly:setMachineTint(trainAssemblerEntity, colorElement[colorElement.name].style.color)

        -- STEP 5: update the color of the build entity (if any)
        local createdEntity = Trainassembly:getCreatedEntity(trainAssemblerLocation.surfaceIndex, trainAssemblerLocation.position)
        if createdEntity then
          local createdEntityColor = Trainassembly:getMachineTint(trainAssemblerEntity)
          if createdEntityColor then
            createdEntity.color = {
              r = createdEntityColor.r,
              g = createdEntityColor.g,
              b = createdEntityColor.b,
              a = createdEntity.color and createdEntity.color.a or 127/255, -- hardcoded for vanilla trains
            }
          end
        end

        -- STEP 6: update opened UI's
        Traincontroller.Gui:updateOpenedGuis(controllerEntity)

        break -- no need to look further
      end
    end

  end



  clickHandlers["traincontroller-color-picker-textfield"] = function(clickedElement, playerIndex)
    local clickedElementValue = clickedElement.text
    clickedElementValue = tonumber(clickedElementValue ~= "" and clickedElementValue or "0") -- if "", we assume 0
    local oldClickedElementValue = clickedElementValue
    if clickedElementValue then -- valid number

      -- STEP1: make sure the value is within limits
      if clickedElementValue < 0   then
        clickedElementValue = 0
      elseif clickedElementValue > 255 then
        clickedElementValue = 255
      else
        clickedElementValue = math.floor(.5 + clickedElementValue)
      end
      if clickedElementValue ~= oldClickedElementValue then
        clickedElement.text = clickedElementValue
      end

      -- STEP2: set the slider value
      local sliderElement = clickedElement.parent["traincontroller-color-picker-slider"]
      if math.floor(.5 + sliderElement.slider_value) ~= clickedElementValue then
        sliderElement.slider_value = clickedElementValue
      else
        return -- no update required
      end

      -- STEP3: update the color button
      local clickedElementStyle        = "traincontroller_color_indicator_button_housing"
      local clickedElementPressedStyle = clickedElementStyle.."_pressed"
      local configurationElement = FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("statistics-builder-configuration-flow"))

      local color
      for _, assemblerElementIndex in pairs(configurationElement.children_names) do
        local colorElement = configurationElement[assemblerElementIndex]["statistics-builder-configuration-button-color"]
        if colorElement and colorElement.style.name == clickedElementPressedStyle then
          -- found the selected one

          color = colorElement[colorElement.name].style.color
          color[string.sub(clickedElement.parent.name, -1)] = clickedElementValue/255
          colorElement[colorElement.name].style.color = color

          break -- no need to look further
        end
      end

      -- STEP4: update the entity preview
      if color then
        local entityRadius = 10
        game.surfaces[Traincontroller.Gui:getControllerSurfaceName()].find_entities_filtered{
          name      = "straight-rail",
          invert    = true,
          position  = {x = 3*entityRadius*playerIndex,
                       y = 0                         },
          radius    = entityRadius,
          limit     = 1,
        }[1].color = {
          r = color.r,
          g = color.g,
          b = color.b,
          a = 127/255, -- hardcoded for vanilla trains
        }
      end

    else -- invalid number
      -- reset the content of the element to the value on the slider
      clickedElement.text = math.floor(.5 + clickedElement.parent["traincontroller-color-picker-slider"].slider_value)
    end
  end



  clickHandlers["traincontroller-color-picker-slider"] = function(clickedElement, playerIndex)
    -- STEP 1: update the textfield
    local clickedElementValue = math.floor(.5 + clickedElement.slider_value)
    local textfieldElement = clickedElement.parent["traincontroller-color-picker-textfield"]
    if tonumber(textfieldElement.text) ~= clickedElementValue then
      textfieldElement.text = ""..clickedElementValue
    else
      return -- no update required
    end

    -- STEP 2: update the color button
    local clickedElementStyle        = "traincontroller_color_indicator_button_housing"
    local clickedElementPressedStyle = clickedElementStyle.."_pressed"
    local configurationElement = FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("statistics-builder-configuration-flow"))

    local color
    for _, assemblerElementIndex in pairs(configurationElement.children_names) do
      local colorElement = configurationElement[assemblerElementIndex]["statistics-builder-configuration-button-color"]
      if colorElement and colorElement.style.name == clickedElementPressedStyle then
        -- found the selected one

        color = colorElement[colorElement.name].style.color
        color[string.sub(clickedElement.parent.name, -1)] = clickedElementValue/255
        colorElement[colorElement.name].style.color = color

        break -- no need to look further
      end
    end

    -- STEP4: update the entity preview
    if color then
      local entityRadius = 10
      game.surfaces[Traincontroller.Gui:getControllerSurfaceName()].find_entities_filtered{
        name      = "straight-rail",
        invert    = true,
        position  = {x = 3*entityRadius*playerIndex,
                     y = 0                         },
        radius    = entityRadius,
        limit     = 1,
      }[1].color = {
        r = color.r,
        g = color.g,
        b = color.b,
        a = 127/255, -- hardcoded for vanilla trains
      }
    end

  end



  ------------------------------------------------------------------------------
  -- select train depot name
  ------------------------------------------------------------------------------
  clickHandlers["selected-depot-list"] = function(clickedElement, playerIndex)
    local listboxElement = FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("selected-depot-list"))

    FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("selected-depot-name")).caption = listboxElement.get_item(listboxElement.selected_index)
  end



  clickHandlers["selected-depot-enter"] = function(clickedElement, playerIndex)
    local controllerEntity  = Traincontroller.Gui:getOpenedControllerEntity(playerIndex)
    if not (controllerEntity and controllerEntity.valid) then return end
    local oldControllerName = controllerEntity.backer_name
    local newControllerName = FLib.gui.getElement(playerIndex, Traincontroller.Gui:getUpdateElementPath("selected-depot-name")).caption

    if newControllerName ~= oldControllerName then
      controllerEntity.backer_name = newControllerName -- invokes the rename event which will update UI's
      --Traincontroller.Gui:updateGuiInfo(playerIndex)
    end

    -- mimic tab pressed to go back to statistics tab
    local tabToOpen = "traincontroller-tab-statistics"
    Traincontroller.Gui:getClickHandler(tabToOpen)(FLib.gui.getElement(playerIndex, Traincontroller.Gui:getTabElementPath(tabToOpen)), playerIndex)
  end



  --------------------
  return clickHandlers
end
Traincontroller.Gui.clickHandlers = Traincontroller.Gui:initClickHandlers()
