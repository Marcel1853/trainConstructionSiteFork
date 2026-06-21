---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Factorio 2.0-safe replacement for the small set of LSlib default styles used
-- by this mod.
--
-- Do NOT call LSlib.styles.addTabStyle() here: older LSlib builds create
-- button styles inheriting from the 2.0 "tab" style (a tab_style), which causes
-- "Style of type Button has parent element tab which has wrong type" during
-- prototype validation. We define/overwrite the needed styles directly.
local guiStyles = data.raw["gui-style"]["default"]

local function set_style(name, style)
  guiStyles[name] = style
end

set_style("centering_horizontal_flow", {
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  horizontal_align = "center",
  vertical_align = "center",
})

set_style("packed_vertical_flow", {
  type = "vertical_flow_style",
  parent = "vertical_flow",
})

set_style("window_content_frame_packed", {
  type = "frame_style",
  parent = "inside_shallow_frame_with_padding",
  graphical_set = {},
})

set_style("LSlib_default_header", {
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  horizontally_stretchable = "on",
  vertical_align = "center",
})

set_style("LSlib_default_frame_title", {
  type = "label_style",
  parent = "frame_title",
})

set_style("LSlib_default_draggable_header", {
  type = "empty_widget_style",
  parent = "draggable_space_header",
  horizontally_stretchable = "on",
  height = 24,
})

set_style("LSlib_default_header_button", {
  type = "button_style",
  parent = "close_button",
})

set_style("LSlib_default_footer_filler", {
  type = "frame_style",
  parent = "frame",
  horizontally_stretchable = "on",
  graphical_set = {},
})

set_style("LSlib_default_tab_buttonFlow", {
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
})

-- These are used on ordinary sprite-button/button GUI elements, so their
-- prototype type must be button_style. In Factorio 2.0 the vanilla "tab" style
-- is a tab_style, not a button_style, therefore it cannot be used as parent.
set_style("LSlib_default_tab_button", {
  type = "button_style",
  parent = "button",
})

set_style("LSlib_default_tab_button_selected", {
  type = "button_style",
  parent = "button",
  default_font_color = {1, 0.9, 0.6},
})

set_style("LSlib_default_tab_insideDeepFrame", {
  type = "frame_style",
  parent = "deep_frame_in_tabbed_pane",
})

set_style("LSlib_default_tab_contentFrame", {
  type = "frame_style",
  parent = "inside_shallow_frame_with_padding",
})
