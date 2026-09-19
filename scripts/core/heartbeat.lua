---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Der einzige Takt der Mod (Regel 5: kein on_tick, ein Heartbeat mit festem Budget).
--
-- Je Takt wird genau ein Controller weitergeschaltet (Zugbau), dazu höchstens alle 120 Ticks
-- ein Durchgang durch die Controller, die noch auf ihren Trainbuilder warten. Der Takt läuft
-- nur, solange es überhaupt etwas zu tun gibt, und wird beim Ändern der Einstellung neu
-- angemeldet. Früher meldeten Zugbau und wartende Controller getrennt `on_nth_tick` an; bei
-- gleicher Zahl hätte die eine Anmeldung die andere überschrieben.

Heartbeat = {}

local PENDING_INTERVAL = 120 -- Ticks zwischen zwei Durchgängen durch die wartenden Controller

local function onHeartbeat(event)
  Traincontroller.Builder:onTick(event)

  local lastCheck = storage.TC_data["pendingControllersChecked"] or 0
  if event.tick - lastCheck >= PENDING_INTERVAL then
    storage.TC_data["pendingControllersChecked"] = event.tick
    Traincontroller:processPendingControllers(event)
  end
end

function Heartbeat:getRate()
  local builderData = storage.TC_data and storage.TC_data.Builder
  return (builderData and builderData["onTickDelay"]) or 5
end

-- Gibt es etwas zu tun? Ein Controller in der Kette oder ein wartender Controller.
function Heartbeat:isNeeded()
  if not storage.TC_data then return false end
  if storage.TC_data["nextTrainControllerIterate"] then return true end
  local pending = storage.TC_data["pendingControllers"]
  return pending ~= nil and next(pending) ~= nil
end

-- Meldet den Takt an oder ab, je nachdem ob etwas zu tun ist. Schreibt storage.
function Heartbeat:sync()
  local builderData = storage.TC_data and storage.TC_data.Builder
  if not builderData then return end

  local wantedRate = self:getRate()
  local activeRate = builderData["onTickActive"] and (builderData["onTickRate"] or wantedRate) or nil

  if activeRate and activeRate ~= wantedRate then
    script.on_nth_tick(activeRate, nil) -- Einstellung geändert: alte Anmeldung weg
    activeRate = nil
  end

  if self:isNeeded() then
    if not activeRate then
      script.on_nth_tick(wantedRate, onHeartbeat)
    end
    builderData["onTickActive"] = true
    builderData["onTickRate"] = wantedRate
  else
    if activeRate then
      script.on_nth_tick(activeRate, nil)
    end
    builderData["onTickActive"] = false
    builderData["onTickRate"] = nil
  end
end

-- Beim Laden nur anmelden, storage darf hier nicht geschrieben werden.
function Heartbeat:onLoad()
  local builderData = storage.TC_data and storage.TC_data.Builder
  if builderData and builderData["onTickActive"] then
    script.on_nth_tick(builderData["onTickRate"] or self:getRate(), onHeartbeat)
  end
end
