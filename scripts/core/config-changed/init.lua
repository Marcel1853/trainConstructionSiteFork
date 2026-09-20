---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- on_configuration_changed: bringt storage auf den aktuellen Stand, wenn sich die Mod-Version ändert.
-- Die Schritte laufen in dieser Reihenfolge; jeder prüft selbst seine Datenversion.

local steps = {
  require("scripts.core.config-changed.prototypes"),
  require("scripts.core.config-changed.assembly"),
  require("scripts.core.config-changed.controller"),
  require("scripts.core.config-changed.controller-gui"),
  require("scripts.core.config-changed.depot"),
  require("scripts.core.config-changed.legacy-help"),
}

return function(configurationData)
  local modChanges = configurationData.mod_changes["trainConstructionSiteFork"] or configurationData.mod_changes["trainConstructionSite"]
  if modChanges and modChanges.new_version ~= (modChanges.old_version or "") then
    log(string.format("Updating trainConstructionSiteFork from version %q to version %q", modChanges.old_version or "nil", modChanges.new_version))

    for _, step in ipairs(steps) do
      step()
    end
  end
end
