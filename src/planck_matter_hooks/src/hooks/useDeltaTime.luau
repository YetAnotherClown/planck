--!nonstrict

-- This file is sourced from Matter by evaera (https://github.com/evaera)
-- License: Copyright (c) 2021 Eryn L. K., MIT License
-- Source: https://github.com/matter-ecs/matter/blob/main/lib/hooks/useDeltaTime.luau

local topoRuntime = require(script.Parent.Parent.topoRuntime)

--[=[
	@within Matter
	@ignore

	:::info Topologically-aware function
	This function is only usable if called within the context of [`Loop:begin`](/api/Loop#begin).
	:::

	Returns the `os.clock()` time delta between the start of this and last frame.
]=]
local function useDeltaTime(): number
	local state = topoRuntime.useFrameState()

	return state.deltaTime
end

return useDeltaTime
