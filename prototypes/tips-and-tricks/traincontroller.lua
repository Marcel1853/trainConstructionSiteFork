---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
data:extend(
  {
    {
      type = "tips-and-tricks-item",
      name = "traincontroller",
      tag = "[item=traincontroller]",
      localised_name = {"item-name.traincontroller", {"item-name.trainassembly"}},
      localised_description = {"",
        {"tips-and-tricks-font-setup.TCS-header", {"tips-and-tricks-item-description.traincontroller-1-h"}},
        {"tips-and-tricks-item-description.traincontroller-1-1"},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.traincontroller-1-2"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-font-setup.TCS-header", {"tips-and-tricks-item-description.traincontroller-2-h"}}},
        {"tips-and-tricks-item-description.traincontroller-2-1"},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.traincontroller-2-2"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.traincontroller-2-3"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.traincontroller-2-4"}},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-font-setup.TCS-header", {"tips-and-tricks-item-description.traincontroller-3-h"}}},
        {"tips-and-tricks-item-description.traincontroller-3-1"},
        {"tips-and-tricks-font-setup.TCS-paragraph", {"tips-and-tricks-item-description.traincontroller-3-2"}},
      },
      category = "trains",
      indent = 2,
      order = "cx-tcs[trainbuilder]-c",
      trigger =
      {
        type = "research",
        technology = "trainassembly-automated-train-assembling"
      },
      dependencies = {"trainassembly"},
      -- Simulation disabled for Factorio 2.0: the old scripted simulation used removed camera/test-player APIs.
    },
    {
      type     = "sprite",
      name     = "tips-and-tricks-traincontroller-gui-1",
      filename = "__trainConstructionSiteFork__/graphics/tips-and-tricks/traincontroller_1.png",
      width    = 433,
      height   = 430,
      scale    = 1.5,
      --shift    = {0, 32},
      flags    = {
        "icon",
        "no-crop"
      }
    },
    {
      type     = "sprite",
      name     = "tips-and-tricks-traincontroller-gui-2",
      filename = "__trainConstructionSiteFork__/graphics/tips-and-tricks/traincontroller_2.png",
      width    = 433,
      height   = 430,
      scale    = 1.5,
      --shift    = {0, 32},
      flags    = {
        "icon",
        "no-crop"
      }
    },
    {
      type     = "sprite",
      name     = "tips-and-tricks-traincontroller-gui-3",
      filename = "__trainConstructionSiteFork__/graphics/tips-and-tricks/traincontroller_3.png",
      width    = 713,
      height   = 430,
      scale    = 1.5,
      --shift    = {0, 32},
      flags    = {
        "icon",
        "no-crop"
      }
    },
    {
      type     = "sprite",
      name     = "tips-and-tricks-traincontroller-gui-4",
      filename = "__trainConstructionSiteFork__/graphics/tips-and-tricks/traincontroller_4.png",
      width    = 713,
      height   = 430,
      scale    = 1.5,
      --shift    = {0, 32},
      flags    = {
        "icon",
        "no-crop"
      }
    },
  }
)
