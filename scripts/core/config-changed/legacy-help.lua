---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Reste der alten Hilfe-GUI entfernen.
-- Teil von on_configuration_changed, siehe init.lua.

return function()
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
