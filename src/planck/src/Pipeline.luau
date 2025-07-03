--!nonstrict
local DependencyGraph = require(script.Parent.DependencyGraph)
local Phase = require(script.Parent.Phase)

--- @class Pipeline
---
--- Pipelines represent a set of ordered Phases. Systems cannot be
--- assigned to Pipelines themselves, but rather to Phases within
--- those Pipelines.
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline:__tostring()
	return self._name
end

--- @method insert
--- @within Pipeline
--- @param phase Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline, ordering it implicitly.
function Pipeline:insert(phase)
	self.dependencyGraph:insert(phase)
	return self
end

--- @method insertAfter
--- @within Pipeline
--- @param phase Phase
--- @param after Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline after another Phase, ordering it explicitly.
function Pipeline:insertAfter(phase, afterPhase)
	local i = table.find(self.dependencyGraph.nodes, afterPhase)
	assert(
		i,
		"Unknown Phase in Pipeline:insertAfter(_, unknown), try adding this Phase to the Pipeline."
	)

	self.dependencyGraph:insertAfter(phase, afterPhase)
	return self
end

--- @method insertBefore
--- @within Pipeline
--- @param phase Phase
--- @param before Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline before another Phase, ordering it explicitly.
function Pipeline:insertBefore(phase, beforePhase)
	local i = table.find(self.dependencyGraph.nodes, beforePhase)
	assert(
		i,
		"Unknown Phase in Pipeline:insertBefore(_, unknown), try adding this Phase to the Pipeline."
	)

	self.dependencyGraph:insertBefore(phase, beforePhase)
	return self
end

--- @within Pipeline
---
--- Creates a new Pipeline, with an optional name to use for debugging.
--- When no name is provided, the script and line number will be used.
function Pipeline.new(name: string?)
	name = name or debug.info(2, "sl")
	return setmetatable({
		_name = name,
		_type = "pipeline",
		dependencyGraph = DependencyGraph.new(),
	}, Pipeline)
end

--- @prop Startup Pipeline
--- @within Pipeline
---
--- A Pipeline containing the `PreStartup`, `Startup`, and `PostStartup` phases.
Pipeline.Startup = Pipeline.new()
	:insert(Phase.PreStartup)
	:insert(Phase.Startup)
	:insert(Phase.PostStartup)

return Pipeline
