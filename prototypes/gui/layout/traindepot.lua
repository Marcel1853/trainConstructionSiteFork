---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

local guiLayout = FLib.gui.layout.create("screen")

local guiFrame = FLib.gui.layout.addFrame(guiLayout, "root", "traindepot-gui", "vertical", {
  --caption = {"item-name.traindepot"},
  style   = "frame",
})

local guiFrameHeaderFlow = FLib.gui.layout.addFlow(guiLayout, guiFrame, "traindepot-gui-header", "horizontal", {
  style = "LSlib_default_header",
})

FLib.gui.layout.addLabel(guiLayout, guiFrameHeaderFlow, "traindepot-gui-header-title", {
  caption = {"item-name.traindepot"},
  style   = "LSlib_default_frame_title",
  ignored_by_interaction = true,
})
FLib.gui.layout.addEmptyWidget(guiLayout, guiFrameHeaderFlow, "traindepot-gui-header-filler", {
  drag_target = guiFrame,
  style       = "LSlib_default_draggable_header",
})
--FLib.gui.layout.addSpriteButton(guiLayout, guiFrameHeaderFlow, "traindepot-help", {
--  sprite = "utility/questionmark"      ,
--  style = "LSlib_default_header_button",
--})
FLib.gui.layout.addSpriteButton(guiLayout, guiFrameHeaderFlow, "traindepot-close", {
  sprite = "utility/close"      ,
  style = "LSlib_default_header_button",
})

local guiTabContent = FLib.gui.layout.addTabs(guiLayout, guiFrame, "traindepot-tab", {
  { -- first tab
    name     = "-statistics"                    ,
    caption  = {"gui-traindepot.tab-statistics"},
    selected = true                             ,
  },
  { -- second tab
    name     = "-selection"                         ,
    caption  = {"gui-traindepot.tab-name-selection"},
  },
}, {
  buttonFlowStyle      = "LSlib_default_tab_buttonFlow"     ,
  buttonStyle          = "LSlib_default_tab_button"         ,
  buttonSelectedStyle  = "LSlib_default_tab_button_selected",
  tabInsideFrameStyle  = "LSlib_default_tab_insideDeepFrame",
  --tabContentFrameStyle = "LSlib_default_tab_contentFrame"   ,
  tabContentFrameStyle = "traindepot_contentFrame"          ,
})



--------------------------------------------------------------------------------
-- Name selection tab                                                         --
--------------------------------------------------------------------------------
local guiTabContent2 = FLib.gui.layout.getTabContentFrameFlow(guiLayout, guiTabContent, 2)

local guiNewEntryFlow = FLib.gui.layout.addFlow(guiLayout, guiTabContent2, "new-entry", "horizontal", {
  style = "traindepot_new_entry_flow",
})

FLib.gui.layout.addLabel(guiLayout, guiNewEntryFlow, "selected-depot-label", {
  caption = {"", {"gui-traindepot.new-name-field"}, " [img=info]"},
  tooltip = {"gui-traindepot.new-name-field-tooltip"},
})
FLib.gui.layout.addTextfield(guiLayout, guiNewEntryFlow, "selected-depot-name", {
  text    = "Enter depot name",
  tooltip = {"gui-traindepot.new-name-field-tooltip"},
  style = "traindepot_new_entry_textfield",
})
FLib.gui.layout.addSpriteButton(guiLayout, guiNewEntryFlow, "selected-depot-enter", {
  sprite = "utility/enter",
  style = "tool_button"   ,
})

FLib.gui.layout.addListbox(guiLayout, guiTabContent2, "selected-depot-list", {
  items = {"test1", "test2", "test3"},
  style = "traindepot_select_name_list_box",
})



--------------------------------------------------------------------------------
-- statistics tab                                                         --
--------------------------------------------------------------------------------
local guiTabContent1 = FLib.gui.layout.getTabContentFrameFlow(guiLayout, guiTabContent, 1)

local statistics = FLib.gui.layout.addTable(guiLayout, guiTabContent1, "statistics", 2, {
  style = "traindepot_statistics_table",
})

-- name
FLib.gui.layout.addLabel(guiLayout, statistics, "statistics-station-id", {
  caption = {"gui-traindepot.depot-name"},
  ignored_by_interaction = true,
})
local stationIDflow = FLib.gui.layout.addFlow(guiLayout, statistics, "statistics-station-id-flow", "horizontal", {
  style = "centering_horizontal_flow",
})
FLib.gui.layout.addLabel(guiLayout, stationIDflow, "statistics-station-id-value", {
  caption = {"gui-traindepot.unused-depot-name"},
  ignored_by_interaction = true,
})
FLib.gui.layout.addSpriteButton(guiLayout, stationIDflow, "statistics-station-id-edit", {
  sprite = "utility/rename_icon",
  style = "mini_button"               ,
})

-- amount
FLib.gui.layout.addLabel(guiLayout, statistics, "statistics-station-amount", {
  caption = {"gui-traindepot.depot-availability"},
  ignored_by_interaction = true,
})
FLib.gui.layout.addLabel(guiLayout, statistics, "statistics-station-amount-value", {
  caption = "-999/999",
  ignored_by_interaction = true,
})

-- traindepos
FLib.gui.layout.addLabel(guiLayout, statistics, "statistics-builderproduct-amount", {
  caption = {"", {"gui-traindepot.depot-auto-request"}, " [img=info]"},
  tooltip = {"gui-traindepot.depot-auto-request-tooltip"},
})
local builderproductFlow = FLib.gui.layout.addFlow(guiLayout, statistics, "statistics-builderproduct-amount-flow", "horizontal", {
  style = "centering_horizontal_flow",
})
FLib.gui.layout.addSpriteButton(guiLayout, builderproductFlow, "statistics-builder-amount-value-", {
  sprite = "utility/editor_speed_down",
  style = "mini_button"               ,
})
FLib.gui.layout.addLabel(guiLayout, builderproductFlow, "statistics-builder-amount-value", {
  caption = "-999/999",
  ignored_by_interaction = true,
})
FLib.gui.layout.addSpriteButton(guiLayout, builderproductFlow, "statistics-builder-amount-value+", {
  sprite = "utility/editor_speed_up",
  style = "mini_button"             ,
})

-- trainbuilders
FLib.gui.layout.addLabel(guiLayout, statistics, "statistics-builders-working-amount", {
  caption = {"", {"gui-traindepot.depot-builder-utilisation"}, " [img=info]"},
  tooltip = {"gui-traindepot.depot-builder-utilisation-tooltip"}
})
FLib.gui.layout.addLabel(guiLayout, statistics, "statistics-builder-working-amount-value", {
  caption = "-999",
  ignored_by_interaction = true,
})
local controllerList = FLib.gui.layout.addScrollPane(guiLayout, guiTabContent1, "statistics-builder-list-flow", {
  horizontal_scroll_policy = "never"                                   ,
  vertical_scroll_policy   = "always"                                  ,
  style                    = "traindepot_controller_minimap_scrollpane",
})
FLib.gui.layout.addTable(guiLayout, controllerList, "statistics-builder-list", 2, {
  style = "traindepot_controller_minimap_table",
})

----------------
return guiLayout
