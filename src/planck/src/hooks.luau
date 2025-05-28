-- Super-duper experimental Plugin Hooks API

local function systemAdd(scheduler, systemInfo)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemAdd]
	local info = {
		scheduler = scheduler,
		system = systemInfo,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function systemRemove(scheduler, systemInfo)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemRemove]
	local info = {
		scheduler = scheduler,
		system = systemInfo,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function systemReplace(scheduler, oldSystemInfo, newSystemInfo)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemReplace]
	local info = {
		scheduler = scheduler,
		new = newSystemInfo,
		old = oldSystemInfo,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function systemCall(scheduler, hookName, systemInfo, nextFn)
	local hooks = scheduler._hooks[scheduler.Hooks[hookName]]

	if hooks then
		for _, hook in hooks do
			nextFn = hook({
				scheduler = nil,
				system = systemInfo,
				nextFn = nextFn,
			})

			if not nextFn then
				local source, line = debug.info(hook, "sl")
				warn(
					`{source}:{line}: Expected 'SystemCall' hook to return a function`
				)
			end
		end
	end

	nextFn()
end

local function systemError(scheduler, systemInfo, err)
	local hooks = scheduler._hooks[scheduler.Hooks["SystemError"]]

	if hooks then
		for _, hook in hooks do
			hook({
				scheduler = scheduler,
				system = systemInfo,
				error = err,
			})
		end
	end
end

type PhaseAdd = {
	scheduler: any,
	phase: any,
}

local function phaseAdd(scheduler, phase)
	local hooks = scheduler._hooks[scheduler.Hooks.PhaseAdd]
	local info = {
		scheduler = scheduler,
		phase = phase,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function phaseBegan(scheduler, phase)
	local hooks = scheduler._hooks[scheduler.Hooks.PhaseBegan]
	local info = {
		scheduler = scheduler,
		phase = phase,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local Hooks = {
	SystemAdd = "SystemAdd",
	SystemRemove = "SystemRemove",
	SystemReplace = "SystemReplace",
	SystemError = "SystemError",

	OuterSystemCall = "OuterSystemCall",
	InnerSystemCall = "InnerSystemCall",
	SystemCall = "SystemCall",

	PhaseAdd = "PhaseAdd",
	PhaseBegan = "PhaseBegan",
}

return {
	Hooks = Hooks,

	systemAdd = systemAdd,
	systemRemove = systemRemove,
	systemReplace = systemReplace,
	systemCall = systemCall,
	systemError = systemError,
	phaseAdd = phaseAdd,
	phaseBegan = phaseBegan,
}
