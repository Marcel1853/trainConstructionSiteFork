---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Bauhilfe für Trainbuilder. Zwei Wagen gehören nur bei genau 7 Feldern Abstand zum selben
-- Builder; dazwischen bleibt ein Feld frei, in das ein Strommast passt.
--   1. Einrasten: ein von Hand gesetzter Wagen rückt auf genau 7 Felder zum Nachbarn.
--   2. Markierungen: die nächsten freien Plätze werden angezeigt, solange der Spieler den
--      Zugbauer in der Hand hält.
-- Gezeichnet wird nur für diese Spieler, und das Bewegungs-Ereignis läuft auch nur dann
-- (Regel 5: kein Dauerbetrieb ohne Anlass).

local BUILDER_SPACING = 7  -- Abstand zweier Wagen eines Builders
local SNAP_RANGE = 10      -- bis hierhin wird zum Nachbarn eingerastet
local HELP_RANGE = 40      -- Umkreis um den Spieler, in dem Plätze gezeigt werden
local MAX_SLOTS = 40       -- Obergrenze der gezeichneten Plätze
local REFRESH_DISTANCE = 6 -- ab dieser Bewegung wird neu gezeichnet

Trainassembly.PlacingHelp = {}

local function isVertical(direction)
  return direction == defines.direction.north or direction == defines.direction.south
end

local function playerSetting(playerIndex, settingName)
  local player = game.get_player(playerIndex)
  if not player then return false end
  local setting = settings.get_player_settings(player)[settingName]
  return setting ~= nil and setting.value == true
end

--------------------------------------------------------------------------------
-- Einrasten
--------------------------------------------------------------------------------
-- Sucht den nächsten Wagen auf derselben Spur und gibt die Position zurück, auf die der neue
-- Wagen gehört: den Platz direkt daneben, genau BUILDER_SPACING entfernt. Gibt nil zurück, wenn
-- kein Nachbar in Reichweite ist, der Platz schon richtig oder belegt ist.
function Trainassembly:snapPositionFor(surface, position, direction, ignoreEntity)
  local vertical = isVertical(direction)
  local axis = vertical and "y" or "x"
  local sideAxis = vertical and "x" or "y"

  local neighbour, neighbourDistance
  for _, candidate in pairs(surface.find_entities_filtered{
    name = self:getMachineEntityName(),
    type = "assembling-machine",
    area = {
      {position.x - SNAP_RANGE, position.y - SNAP_RANGE},
      {position.x + SNAP_RANGE, position.y + SNAP_RANGE},
    },
  }) do
    if candidate ~= ignoreEntity and candidate.valid and isVertical(candidate.direction) == vertical
       and math.abs(candidate.position[sideAxis] - position[sideAxis]) < 1 then
      local distance = math.abs(candidate.position[axis] - position[axis])
      if distance > 0.1 and distance <= SNAP_RANGE and (not neighbourDistance or distance < neighbourDistance) then
        neighbour, neighbourDistance = candidate, distance
      end
    end
  end
  if not neighbour then return nil end

  -- auf den Platz direkt neben dem Nachbarn ziehen
  local offset = neighbour.position[axis] - position[axis]
  local target = {x = position.x, y = position.y}
  target[axis] = neighbour.position[axis] - (offset > 0 and 1 or -1) * BUILDER_SPACING
  target[sideAxis] = neighbour.position[sideAxis] -- auch seitlich auf die Spur des Nachbarn

  if math.abs(target.x - position.x) < 0.01 and math.abs(target.y - position.y) < 0.01 then
    return nil -- steht schon richtig
  end
  if not self.PlacingHelp:slotIsFree(surface, target, ignoreEntity) then return nil end
  return target
end

function Trainassembly:snapToNeighbour(machineEntity)
  return self:snapPositionFor(machineEntity.surface, machineEntity.position, machineEntity.direction, machineEntity)
end

-- Rückt einen von Hand gesetzten Wagen auf den festen Abstand, wenn die Einstellung an ist.
function Trainassembly:trySnapPlacement(createdEntity, playerIndex)
  if not (playerIndex and playerSetting(playerIndex, "trainassembly-snap-placement")) then return end
  local target = self:snapToNeighbour(createdEntity)
  if target then createdEntity.teleport(target) end
end

--------------------------------------------------------------------------------
-- Markierungen
--------------------------------------------------------------------------------
function Trainassembly.PlacingHelp:slotIsFree(surface, position, ignoreEntity)
  for _, machineEntity in pairs(surface.find_entities_filtered{
    name = Trainassembly:getMachineEntityName(),
    type = "assembling-machine",
    area = {{position.x - 2.9, position.y - 2.9}, {position.x + 2.9, position.y + 2.9}},
  }) do
    if machineEntity ~= ignoreEntity then return false end
  end
  return true
end

local function railFits(surface, position, vertical)
  for _, railEntity in pairs(surface.find_entities_filtered{
    type = {"straight-rail", "legacy-straight-rail"},
    area = {{position.x - 0.6, position.y - 0.6}, {position.x + 0.6, position.y + 0.6}},
  }) do
    if isVertical(railEntity.direction) == vertical then return true end
  end
  return false
end

-- Freie Plätze neben den Buildern im Umkreis des Spielers
function Trainassembly.PlacingHelp:getSlots(surface, center)
  local slots, seen = {}, {}
  for _, machineEntity in pairs(surface.find_entities_filtered{
    name = Trainassembly:getMachineEntityName(),
    type = "assembling-machine",
    area = {{center.x - HELP_RANGE, center.y - HELP_RANGE}, {center.x + HELP_RANGE, center.y + HELP_RANGE}},
  }) do
    local vertical = isVertical(machineEntity.direction)
    for _, offset in pairs{-BUILDER_SPACING, BUILDER_SPACING} do
      local position = vertical
        and {x = machineEntity.position.x, y = machineEntity.position.y + offset}
        or  {x = machineEntity.position.x + offset, y = machineEntity.position.y}
      local key = position.x .. "/" .. position.y
      if (not seen[key]) and #slots < MAX_SLOTS and self:slotIsFree(surface, position)
         and railFits(surface, position, vertical) then
        seen[key] = true
        slots[#slots + 1] = position
      end
    end
  end
  return slots
end

local function helpData()
  storage.TA_data["placingHelp"] = storage.TA_data["placingHelp"] or {}
  return storage.TA_data["placingHelp"]
end

function Trainassembly.PlacingHelp:clear(playerIndex)
  local data = helpData()[playerIndex]
  if not data then return end
  for _, renderObject in pairs(data.renders or {}) do
    if renderObject.valid then renderObject.destroy() end
  end
  helpData()[playerIndex] = nil
end

function Trainassembly.PlacingHelp:draw(player)
  self:clear(player.index)
  local renders = {}
  for _, position in pairs(self:getSlots(player.surface, player.position)) do
    renders[#renders + 1] = rendering.draw_rectangle{
      color = {r = 0.2, g = 0.8, b = 0.3, a = 0.5},
      width = 3,
      filled = false,
      left_top = {position.x - 2.9, position.y - 2.9},
      right_bottom = {position.x + 2.9, position.y + 2.9},
      surface = player.surface,
      players = {player.index},
      draw_on_ground = true,
    }
    renders[#renders + 1] = rendering.draw_sprite{
      sprite = "item/" .. Trainassembly:getItemName(),
      target = position,
      surface = player.surface,
      players = {player.index},
      x_scale = 0.8,
      y_scale = 0.8,
      tint = {r = 1, g = 1, b = 1, a = 0.6},
    }
  end
  helpData()[player.index] = {
    renders = renders,
    position = {x = player.position.x, y = player.position.y},
  }
end

-- Hält der Spieler den Zugbauer in der Hand? Dann zeichnen, sonst aufräumen.
function Trainassembly.PlacingHelp:refresh(playerIndex)
  local player = game.get_player(playerIndex)
  local cursor = player and player.cursor_stack
  local holdsItem = cursor ~= nil and cursor.valid_for_read and cursor.name == Trainassembly:getItemName()
  if holdsItem and playerSetting(playerIndex, "trainassembly-placing-help") then
    self:draw(player)
  else
    self:clear(playerIndex)
  end
  self:syncMoveEvent()
end

function Trainassembly.PlacingHelp:refreshAll()
  for playerIndex in pairs(helpData()) do
    self:refresh(playerIndex)
  end
end

--------------------------------------------------------------------------------
-- Ereignisse
--------------------------------------------------------------------------------
-- Das Bewegungs-Ereignis läuft nur, solange jemand Markierungen sieht.
function Trainassembly.PlacingHelp:syncMoveEvent()
  if next(helpData()) then
    script.on_event(defines.events.on_player_changed_position, function(event)
      Trainassembly.PlacingHelp:onPlayerMoved(event.player_index)
    end)
  else
    script.on_event(defines.events.on_player_changed_position, nil)
  end
end

function Trainassembly.PlacingHelp:onLoad()
  -- storage darf hier nur gelesen werden
  if storage.TA_data and storage.TA_data["placingHelp"] and next(storage.TA_data["placingHelp"]) then
    script.on_event(defines.events.on_player_changed_position, function(event)
      Trainassembly.PlacingHelp:onPlayerMoved(event.player_index)
    end)
  end
end

function Trainassembly.PlacingHelp:onPlayerMoved(playerIndex)
  local data = helpData()[playerIndex]
  if not data then return end
  local player = game.get_player(playerIndex)
  if not player then return end
  local dx = player.position.x - data.position.x
  local dy = player.position.y - data.position.y
  if dx * dx + dy * dy >= REFRESH_DISTANCE * REFRESH_DISTANCE then
    self:refresh(playerIndex)
  end
end

function Trainassembly.PlacingHelp:onCursorChanged(playerIndex)
  self:refresh(playerIndex)
end

function Trainassembly.PlacingHelp:onPlayerLeftGame(playerIndex)
  self:clear(playerIndex)
  self:syncMoveEvent()
end
