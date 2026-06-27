---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Compatibility loader: loads FactoryLib which provides the FLib global.
-- Falls back to LSlib_James_Fork if FactoryLib is not available.

if not rawget(_G, "FLib") then
  local active_mods = mods or (script and script.active_mods) or {}

  if active_mods["FactoryLib"] then
    require("__FactoryLib__/FactoryLib")
  elseif active_mods["LSlib_James_Fork"] then
    require("__LSlib_James_Fork__/LSlib")
  else
    pcall(require, "__FactoryLib__/FactoryLib")
  end
end

-- Patch direction helpers for expanded Factorio 2.1 direction enum.
if FLib and FLib.utils and FLib.utils.directions and defines and defines.direction then
  local d = defines.direction
  local north = d.north or 0
  local east  = d.east  or 2
  local south = d.south or 4
  local west  = d.west  or 6

  local opposite = {
    [d.north or 0] = d.south or 4,  [d.northeast or 1] = d.southwest or 5,
    [d.east  or 2] = d.west  or 6,  [d.southeast or 3] = d.northwest or 7,
    [d.south or 4] = d.north or 0,  [d.southwest or 5] = d.northeast or 1,
    [d.west  or 6] = d.east  or 2,  [d.northwest or 7] = d.southeast or 3,
  }
  local names = {
    [d.north or 0]="north", [d.northeast or 1]="northeast",
    [d.east  or 2]="east",  [d.southeast or 3]="southeast",
    [d.south or 4]="south", [d.southwest or 5]="southwest",
    [d.west  or 6]="west",  [d.northwest or 7]="northwest",
  }

  FLib.utils.directions.oposite = function(direction)
    return opposite[direction] or direction
  end
  FLib.utils.directions.opposite = FLib.utils.directions.oposite

  FLib.utils.directions.toString = function(direction)
    return names[direction] or "north"
  end

  FLib.utils.directions.orientationTo4WayDirection = function(orientation)
    orientation = (orientation or 0) % 1
    if orientation >= 0.875 or orientation < 0.125 then return north
    elseif orientation < 0.375 then return east
    elseif orientation < 0.625 then return south
    else return west end
  end
end

return FLib
