---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
data:extend(
  {
    {
      type = "tips-and-tricks-item",
      name = "traindepot",
      tag = "[item=traindepot]",
      localised_name = {"item-name.traindepot"},
      localised_description = {"",
        {"tips-and-tricks-font-setup.TCS-header", {"tips-and-tricks-item-description.traindepot-1-h"}},
        {"tips-and-tricks-item-description.traindepot-1-1"},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.traindepot-1-2"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-font-setup.TCS-header", {"tips-and-tricks-item-description.traindepot-2-h"}}},
        {"tips-and-tricks-item-description.traindepot-2-1"},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.traindepot-2-2"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.traindepot-2-3"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-font-setup.TCS-header", {"tips-and-tricks-item-description.traindepot-3-h"}}},
        {"tips-and-tricks-item-description.traindepot-3-1"},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.traindepot-3-2"}},
      },
      category = "trains",
      indent = 2,
      order = "cx-tcs[trainbuilder]-a",
      trigger =
      {
        type = "research",
        technology = "automated-rail-transportation"
      },
      dependencies = {"train-stops"},
      -- Simulation disabled for Factorio 2.0: the old scripted simulation used removed camera/test-player APIs.
    }   
  }
)
