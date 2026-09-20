---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Traincontroller.Gui: Klick-Handler der Farbauswahl (Zugfarbe je Wagen).
-- Wird von scripts/gui/controller/click-handlers.lua eingehängt.

function Traincontroller.Gui:addColorPickerHandlers(clickHandlers)
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



  return clickHandlers
end
