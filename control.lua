---@diagnostic disable: undefined-global, inject-field, assign-type-mismatch, param-type-mismatch, redundant-parameter, missing-fields, deprecated, duplicate-set-field, different-requires, redefined-local, undefined-field, need-check-nil, cast-local-type
-- Runtime-Einstieg: nur verdrahten, die Logik liegt in scripts/.
require("util")
require("compat.lslib")

require("scripts.depot.init")
require("scripts.assembly.init")
require("scripts.controller.init")
require("scripts.assembly.fuel")
require("scripts.compat.mod-compatibility")
require("scripts.core.debug")
require("scripts.api.remote")

require("scripts.core.events")
