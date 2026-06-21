---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
data:extend{
  {
    -- If trains can be manually placed on tracks. Runtime-global because
    -- script enforcement can enable/disable it without rebuilding prototypes.
    setting_type = "runtime-global",
    name = "trainController-manual-placing-trains",
    type = "bool-setting",
    default_value = false,
    order = "trainController-b[manual-placing-trains]",
  },
  {
    -- If speed modules are allowed in the Trainbuilder
    setting_type = "startup",
    name = "trainController-allow-speed-modules",
    type = "bool-setting",
    default_value = false,
    order = "trainController-c[allow-speed-modules]",
  },
  {
    -- Ticks between builder updates
    setting_type = "runtime-global",
    name = "trainController-tickRate", -- in ticks
    type = "int-setting",
    minimum_value = 1,
    maximum_value = 60,
    default_value = 5,
    order = "trainController-a[tickRate]",
  },
}
