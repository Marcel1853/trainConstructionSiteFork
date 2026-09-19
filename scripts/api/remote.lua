---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

-- Remote interface for Train Construction Site Manager Addon
-- Provides access to storage tables and helper methods

remote.add_interface("trainConstructionSite", {
  get_manager_data = function()
    return {
      TD_data = storage.TD_data,
      TC_data = storage.TC_data,
      TA_data = storage.TA_data
    }
  end,

  -- Baut alle Trainbuilder-Daten neu auf und verbindet die Controller neu (Reparatur, Tests).
  rebuild_train_builders = function()
    Trainassembly:rebuildTrainBuilders()
  end,

  -- Auf welchen Platz rastet ein hier gesetzter Zugbauer ein? nil = kein Einrasten. (Tests, Werkzeuge)
  get_snap_position = function(surface_index, position, direction)
    local surface = game.surfaces[surface_index]
    if not surface then return nil end
    return Trainassembly:snapPositionFor(surface, position, direction)
  end,

  -- Freie Plätze für Zugbauer im Umkreis einer Position. (Tests, Werkzeuge)
  get_placing_help_slots = function(surface_index, position)
    local surface = game.surfaces[surface_index]
    if not surface then return {} end
    return Trainassembly.PlacingHelp:getSlots(surface, position)
  end,

  open_entity_gui = function(player_index, surface_index, x, y)
    local player = game.players[player_index]
    local surf = game.surfaces[surface_index]
    if player and surf then
      local ents = surf.find_entities_filtered { position = { x, y }, radius = 1.5 }
      for _, e in pairs(ents) do
        if e.valid and (e.name == "traindepot" or e.name == "traincontroller" or e.name == "trainassembly-machine" or e.name == "trainassembly-placeable") then
          player.opened = e
          if Traindepot and Traindepot.Gui and e.name == "traindepot" then
            Traindepot.Gui:onOpenEntity(e, player_index)
          elseif Traincontroller and Traincontroller.Gui and e.name == "traincontroller" then
            Traincontroller.Gui:onOpenEntity(e, player_index)
          end
          break
        end
      end
    end
  end
})
