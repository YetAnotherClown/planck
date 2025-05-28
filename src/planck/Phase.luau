--- @class Phase
---
--- Phases represent tags that tell the scheduler when to
--- schedule a set of systems.
local Phase = {}
Phase.__index = Phase

function Phase:__tostring()
	return self._name
end

--- @within Phase
---
--- Creates a new Phase, with an optional name to use for debugging.
--- When no name is provided, the script and line number will be used.
function Phase.new(name: string?)
	name = name or debug.info(2, "sl")
	return setmetatable({
		_name = name,
		_type = "phase",
	}, Phase)
end

--- @prop PreStartup Phase
--- @within Phase
--- Runs before the `Startup` Phase.

--- @prop Startup Phase
--- @within Phase
--- This Phase will run once, the first time the Scheduler is ran,
--- before any other Phases are ran.

--- @prop PostStartup Phase
--- @within Phase
--- Runs after the `Startup` phase.

Phase.PreStartup = Phase.new("PreStartup")
Phase.Startup = Phase.new("Startup")
Phase.PostStartup = Phase.new("PostStartup")

return Phase
