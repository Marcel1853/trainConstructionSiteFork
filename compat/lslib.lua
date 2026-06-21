---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Compatibility loader for LovelySanta's LSlib on Factorio 2.0.
-- The original mod depended on "LSlib". For Factorio 2.0 the actively
-- maintained mod-portal package is "LSlib_James_Fork". This wrapper supports
-- both package names and patches the old 4-way direction helpers for the
-- expanded Factorio 2.0 direction enum.

local active_mods = mods or (script and script.active_mods) or {}

if not rawget(_G, "LSlib") then
  if active_mods["LSlib_James_Fork"] then
    require("__LSlib_James_Fork__/LSlib")
  elseif active_mods["LSlib"] then
    require("compat.lslib")
  else
    local ok = pcall(require, "__LSlib_James_Fork__/LSlib")
    if not ok then
      require("compat.lslib")
    end
  end
end

local function patch_lslib_directions()
  if not (LSlib and LSlib.utils and LSlib.utils.directions and defines and defines.direction) then
    return
  end

  local d = defines.direction
  local north     = d.north     or 0
  local northeast = d.northeast or north
  local east      = d.east      or 2
  local southeast = d.southeast or east
  local south     = d.south     or 4
  local southwest = d.southwest or south
  local west      = d.west      or 6
  local northwest = d.northwest or west

  local opposite = {
    [north]     = south,
    [northeast] = southwest,
    [east]      = west,
    [southeast] = northwest,
    [south]     = north,
    [southwest] = northeast,
    [west]      = east,
    [northwest] = southeast,
  }

  local names = {
    [north]     = "north",
    [northeast] = "northeast",
    [east]      = "east",
    [southeast] = "southeast",
    [south]     = "south",
    [southwest] = "southwest",
    [west]      = "west",
    [northwest] = "northwest",
  }

  -- Keep LSlib's misspelled public API name for backwards compatibility.
  LSlib.utils.directions.oposite = function(direction)
    return opposite[direction] or direction
  end
  LSlib.utils.directions.opposite = LSlib.utils.directions.oposite

  LSlib.utils.directions.toString = function(direction)
    return names[direction] or "north"
  end

  LSlib.utils.directions.orientationTo4WayDirection = function(orientation)
    orientation = (orientation or 0) % 1
    if orientation >= 0.875 or orientation < 0.125 then
      return north
    elseif orientation < 0.375 then
      return east
    elseif orientation < 0.625 then
      return south
    else
      return west
    end
  end
end

patch_lslib_directions()

return LSlib
