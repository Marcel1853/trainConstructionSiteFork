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
