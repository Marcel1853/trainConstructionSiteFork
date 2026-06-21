---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
data:extend(
  {
    {
      type = "tips-and-tricks-item",
      name = "TCS-train-building",
      tag = "[entity=locomotive]",
      localised_name = {"tips-and-tricks-item-name.TCS-train-building"},
      localised_description = {"",
        {"tips-and-tricks-font-setup.TCS-header", {"tips-and-tricks-item-description.TCS-introduction-1-h"}},
        {"tips-and-tricks-item-description.TCS-introduction-1-1", {"tips-and-tricks-item-description.TCS-introduction-1-1-a"}},--todo 1-1-b
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.TCS-introduction-1-2"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.TCS-introduction-1-3"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.TCS-introduction-1-4"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.TCS-introduction-1-5"}},
      },
      category = "trains",
      indent = 2,
      order = "bx-tcs[introduction]",
      trigger =
      {
        type = "build-entity",
        entity = "straight-rail",
        count = 3
      },
      dependencies = {"rail-building"},
      -- Simulation disabled for Factorio 2.0: the old scripted simulation used removed camera/test-player APIs.
    }   
  }
)
