---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
local compat = {}

function compat.get_render_object(render_object)
  if type(render_object) == "userdata" then
    return render_object
  end
  if type(render_object) == "number" and rendering and rendering.get then
    local ok, object = pcall(rendering.get, render_object)
    if ok then
      return object
    end
  end
  return nil
end

function compat.destroy_render_object(render_object)
  local object = compat.get_render_object(render_object)
  if object and object.valid then
    object.destroy()
  end
end

function compat.set_render_animation(render_object, animation)
  local object = compat.get_render_object(render_object)
  if object and object.valid then
    object.animation = animation
  end
end

function compat.set_render_sprite(render_object, sprite)
  local object = compat.get_render_object(render_object)
  if object and object.valid then
    object.sprite = sprite
  end
end

function compat.set_render_target(render_object, target, offset)
  local object = compat.get_render_object(render_object)
  if object and object.valid then
    if offset then
      object.target = {entity = target, offset = offset}
    else
      object.target = target
    end
  end
end

function compat.set_train_schedule(train, train_schedule)
  if not (train and train.valid and train_schedule) then
    return
  end

  if train.get_schedule then
    local schedule = train.get_schedule()
    if schedule and schedule.set_records then
      schedule.set_records(train_schedule.records or {})
      if train_schedule.current and schedule.go_to_station and train_schedule.records and #train_schedule.records > 0 then
        pcall(function()
          schedule.go_to_station(train_schedule.current)
        end)
      end
      return
    end
  end

  -- 1.1 fallback, kept harmless for compatibility if this code is ever loaded there.
  train.schedule = train_schedule
end

return compat
