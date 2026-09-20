---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Letzter Schritt beim Laden: die eigene Gruppe „Transport-Logistik“ wieder entfernen, wenn
-- nichts mehr darin liegt. Das passiert, wenn eine andere Mod (etwa eine Überarbeitung) alle
-- Zugteile in ihre eigene Gruppe einsortiert – dann bliebe hier sonst ein leerer Reiter stehen.

local GROUP = "transport-logistics"

-- Untergruppen dieser Gruppe, getrennt nach eigenen und übernommenen (die gehören anderen Mods
-- oder dem Grundspiel und werden nur wieder freigegeben).
local OWN_SUBGROUPS = {
  ["transport-railway"] = true,
  ["trainassembler-fuel"] = true,
  ["manual-buildable-vehicles"] = true,
  ["trainparts-fluid"] = true,
}

if not (data.raw["item-group"] and data.raw["item-group"][GROUP]) then return end

-- STEP 1: alle Untergruppen dieser Gruppe sammeln
local subgroups = {}
for subgroupName, subgroup in pairs(data.raw["item-subgroup"] or {}) do
  if subgroup.group == GROUP then
    subgroups[subgroupName] = true
  end
end

-- STEP 2: liegt irgendein Prototyp (Item, Rezept, …) in einer dieser Untergruppen?
local used = false
for _, prototypes in pairs(data.raw) do
  if used then break end
  for _, prototype in pairs(prototypes) do
    if type(prototype) == "table" and prototype.subgroup and subgroups[prototype.subgroup] then
      used = true
      break
    end
  end
end

if used then return end -- alles gut, die Gruppe wird gebraucht

-- STEP 3: nichts drin – eigene Untergruppen löschen, fremde zurück in „logistics“ geben
log("Train Construction Site Fork: item group " .. GROUP .. " is empty, removing it.")
for subgroupName in pairs(subgroups) do
  if OWN_SUBGROUPS[subgroupName] then
    data.raw["item-subgroup"][subgroupName] = nil
  else
    data.raw["item-subgroup"][subgroupName].group = "logistics"
  end
end
data.raw["item-group"][GROUP] = nil
