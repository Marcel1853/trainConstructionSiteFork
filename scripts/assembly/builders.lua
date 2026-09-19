---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type

-- Verwaltung der Trainbuilder: welche Wagen (trainassembly-machine) zusammen einen Builder bilden.
--
-- Datenstruktur (storage.TA_data):
--   trainAssemblers[surfaceIndex][y][x].trainBuilderIndex  -> Nummer des Builders
--   trainBuilders[index] = { {surfaceIndex=…, position={x=…, y=…}}, … }  (Liste ohne Lücken)
--   nextTrainBuilderIndex                                   -> nächste freie Nummer
--
-- Builder-Nummern werden nie umnummeriert. Früher wurde der letzte Builder in eine frei
-- gewordene Nummer verschoben, ohne die Controller anzupassen – danach zeigten Controller
-- auf fremde oder leere Builder. Frei gewordene Nummern bleiben jetzt einfach leer.

local BUILDER_SPACING = 7 -- Abstand zweier Wagen eines Builders in Feldern

local function isVertical(direction)
  return direction == defines.direction.north or direction == defines.direction.south
end

local function copyLocation(surfaceIndex, position)
  return { ["surfaceIndex"] = surfaceIndex, ["position"] = { x = position.x, y = position.y } }
end

-- Liefert die gespeicherten Daten eines Wagens oder nil.
function Trainassembly:getAssemblerData(surfaceIndex, position)
  local surfaceData = storage.TA_data["trainAssemblers"][surfaceIndex]
  local row = surfaceData and surfaceData[position.y]
  return row and row[position.x]
end

function Trainassembly:newTrainBuilderIndex()
  local index = storage.TA_data["nextTrainBuilderIndex"]
  storage.TA_data["nextTrainBuilderIndex"] = index + 1
  return index
end

-- Speichert einen Builder als Liste ohne Lücken und lässt alle seine Wagen auf ihn zeigen.
-- Eine leere Liste löscht den Builder.
function Trainassembly:setTrainBuilder(trainBuilderIndex, locations)
  local builder = {}
  for _, location in pairs(locations) do
    local assemblerData = self:getAssemblerData(location.surfaceIndex, location.position)
    if assemblerData then
      assemblerData["trainBuilderIndex"] = trainBuilderIndex
      builder[#builder + 1] = copyLocation(location.surfaceIndex, location.position)
    end
  end
  storage.TA_data["trainBuilders"][trainBuilderIndex] = (#builder > 0) and builder or nil
end

-- Sucht die Nachbar-Wagen (davor/dahinter, gleiche Achse) eines Wagens.
local function findNeighbour(machineEntity, offset)
  local position = machineEntity.position
  local target = isVertical(machineEntity.direction)
    and { x = position.x, y = position.y + offset }
    or  { x = position.x + offset, y = position.y }
  local neighbour = machineEntity.surface.find_entities_filtered{
    name     = machineEntity.name,
    type     = machineEntity.type,
    force    = machineEntity.force,
    position = target,
    limit    = 1,
  }[1]
  if not (neighbour and neighbour.valid) then return nil end
  if isVertical(neighbour.direction) ~= isVertical(machineEntity.direction) then return nil end
  return neighbour
end

-- Hängt einen frisch gespeicherten Wagen an einen Builder an (neu, verlängern oder zwei verbinden).
function Trainassembly:addToTrainBuilder(machineEntity)
  local surfaceIndex = machineEntity.surface.index
  local position = machineEntity.position

  local neighbourIndices = {}
  for _, offset in pairs{ -BUILDER_SPACING, BUILDER_SPACING } do
    local neighbour = findNeighbour(machineEntity, offset)
    local neighbourIndex = neighbour and self:getTrainBuilderIndex(neighbour)
    if neighbourIndex and storage.TA_data["trainBuilders"][neighbourIndex] then
      neighbourIndices[#neighbourIndices + 1] = neighbourIndex
    end
  end

  if #neighbourIndices == 0 then
    self:setTrainBuilder(self:newTrainBuilderIndex(), { copyLocation(surfaceIndex, position) })
    return
  end

  -- Ein oder zwei Nachbarn: alles im ersten Nachbar-Builder zusammenführen.
  local targetIndex = neighbourIndices[1]
  local locations = {}
  for _, neighbourIndex in pairs(neighbourIndices) do
    Traincontroller:onTrainbuilderAltered(neighbourIndex)
    for _, location in pairs(storage.TA_data["trainBuilders"][neighbourIndex] or {}) do
      locations[#locations + 1] = location
    end
  end
  locations[#locations + 1] = copyLocation(surfaceIndex, position)

  for _, neighbourIndex in pairs(neighbourIndices) do
    if neighbourIndex ~= targetIndex then
      storage.TA_data["trainBuilders"][neighbourIndex] = nil
    end
  end
  self:setTrainBuilder(targetIndex, locations)
end

-- Nimmt einen Wagen aus seinem Builder. Liegt er in der Mitte, wird der Builder geteilt.
function Trainassembly:removeFromTrainBuilder(machineEntity)
  local surfaceIndex = machineEntity.surface.index
  local position = machineEntity.position
  local assemblerData = self:getAssemblerData(surfaceIndex, position)
  if not assemblerData then return end

  local trainBuilderIndex = assemblerData["trainBuilderIndex"]
  local builder = trainBuilderIndex and storage.TA_data["trainBuilders"][trainBuilderIndex]
  if not builder then return end

  Traincontroller:onTrainbuilderAltered(trainBuilderIndex)

  local axis = isVertical(assemblerData["direction"] or machineEntity.direction) and "y" or "x"
  local before, after = {}, {}
  for _, location in pairs(builder) do
    local samePlace = location.surfaceIndex == surfaceIndex and
                      location.position.x == position.x and location.position.y == position.y
    if not samePlace then
      if location.position[axis] < position[axis] then
        before[#before + 1] = location
      else
        after[#after + 1] = location
      end
    end
  end

  assemblerData["trainBuilderIndex"] = nil
  storage.TA_data["trainBuilders"][trainBuilderIndex] = nil
  if #after > 0 then
    self:setTrainBuilder(trainBuilderIndex, after)
    if #before > 0 then
      self:setTrainBuilder(self:newTrainBuilderIndex(), before)
    end
  elseif #before > 0 then
    self:setTrainBuilder(trainBuilderIndex, before)
  end
end

-- Baut alle Builder aus den gespeicherten Wagen neu auf und verbindet die Controller neu.
-- Repariert Spielstände, deren Builder-Daten durch das alte Umnummerieren kaputt sind.
-- Controller, die keinen passenden Builder mehr finden, warten wie Bot-gebaute Controller.
function Trainassembly:rebuildTrainBuilders()
  if not (storage.TA_data and storage.TA_data["trainAssemblers"]) then return end

  -- STEP 1: Wagen ohne gültige Entity aus den Daten nehmen
  local machines = {}
  for surfaceIndex, surfaceData in pairs(storage.TA_data["trainAssemblers"]) do
    for y, row in pairs(surfaceData) do
      for x, assemblerData in pairs(row) do
        if assemblerData.entity and assemblerData.entity.valid then
          assemblerData["trainBuilderIndex"] = nil
          machines[#machines + 1] = assemblerData.entity
        else
          row[x] = nil
        end
      end
      if not next(row) then surfaceData[y] = nil end
    end
    if not next(surfaceData) then storage.TA_data["trainAssemblers"][surfaceIndex] = nil end
  end

  -- STEP 2: Builder neu zusammensetzen (Reihenfolge wie beim Bauen, ohne Controller-Änderungen)
  storage.TA_data["trainBuilders"] = {}
  storage.TA_data["nextTrainBuilderIndex"] = 1
  for _, machineEntity in pairs(machines) do
    local neighbourIndices = {}
    for _, offset in pairs{ -BUILDER_SPACING, BUILDER_SPACING } do
      local neighbour = findNeighbour(machineEntity, offset)
      local neighbourIndex = neighbour and self:getTrainBuilderIndex(neighbour)
      if neighbourIndex then neighbourIndices[#neighbourIndices + 1] = neighbourIndex end
    end
    local locations = { copyLocation(machineEntity.surface.index, machineEntity.position) }
    local targetIndex = neighbourIndices[1] or self:newTrainBuilderIndex()
    for _, neighbourIndex in pairs(neighbourIndices) do
      for _, location in pairs(storage.TA_data["trainBuilders"][neighbourIndex] or {}) do
        locations[#locations + 1] = location
      end
      if neighbourIndex ~= targetIndex then storage.TA_data["trainBuilders"][neighbourIndex] = nil end
    end
    self:setTrainBuilder(targetIndex, locations)
  end

  -- STEP 3: Controller neu verbinden
  if not (storage.TC_data and storage.TC_data["trainControllers"]) then return end
  local controllers = {}
  for _, surfaceData in pairs(storage.TC_data["trainControllers"]) do
    for _, row in pairs(surfaceData) do
      for _, controllerData in pairs(row) do
        controllerData["trainBuilderIndex"] = nil
        controllers[#controllers + 1] = controllerData
      end
    end
  end
  for _, controllerData in pairs(controllers) do
    local controllerEntity = controllerData.entity
    if controllerEntity and controllerEntity.valid then
      local validPlacement, trainBuilderIndex = Traincontroller:checkValidPlacement(controllerEntity, nil, true)
      if validPlacement then
        controllerData["trainBuilderIndex"] = trainBuilderIndex
      else
        Traincontroller:deleteController(controllerEntity)
        -- Aktive Controller stehen auf der Controller-Force; beim erneuten Aktivieren wird sie
        -- wieder angehängt, daher zurück auf die Force des Depots.
        local forceName = controllerEntity.force.name
        local suffix = storage.TC_data.prototypeData.trainControllerForce
        if forceName:sub(-#suffix) == suffix then
          controllerEntity.force = Traincontroller:getDepotForceName(forceName)
        end
        Traincontroller:addPendingController(controllerEntity)
      end
    end
  end
end
