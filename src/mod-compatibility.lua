---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
require 'util'
require("compat.lslib")

-- Create class
ModCompatibility = {}

-------------------------------------------------------------------------------
-- Initiation of the class
-------------------------------------------------------------------------------
function ModCompatibility:onInit()
  self:PickerDollies_RegisterInterface()
end

function ModCompatibility:onLoad()
  self:PickerDollies_RegisterInterface()
end

-------------------------------------------------------------------------------
-- Picker Dollies
-------------------------------------------------------------------------------
function ModCompatibility:PickerDollies_RegisterInterface()
  if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]['add_blacklist_name'] then
    local blacklist = function(entity_name)
      remote.call("PickerDollies", 'add_blacklist_name', entity_name, true)
    end

    blacklist(Trainassembly:getPlaceableEntityName())
    blacklist(Trainassembly:getMachineEntityName())
    blacklist(Traincontroller:getControllerEntityName())
  end
end