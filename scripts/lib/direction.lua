---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Richtung einer Entity auf eine der 4 Hauptrichtungen runden (Züge und Gebäude drehen in 2.x 16-fach).

return function(entity)
  local direction = entity and entity.direction
  if direction == defines.direction.north or
     direction == defines.direction.east  or
     direction == defines.direction.south or
     direction == defines.direction.west then
    return direction
  end
  return FLib.utils.directions.orientationTo4WayDirection(entity and entity.orientation or 0)
end
