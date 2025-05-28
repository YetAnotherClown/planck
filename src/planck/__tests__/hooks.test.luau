local JestGlobals = require("@DevPackages/JestGlobals")

local Planck = require("@Project")

local Phase = Planck.Phase
local Scheduler = Planck.Scheduler

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

describe("topoRuntime", function()
	test("useDeltaTime", function()
		local matterHooks = require("@Plugins/planck_matter_hooks/src")
		local useDeltaTime = matterHooks.useDeltaTime
		expect.assertions(1)

		local plugin = matterHooks.Plugin.new()

		local myPhase = Phase.new("myPhase")
		local myScheduler = Scheduler.new(1, 2, 3)
			:addPlugin(plugin)
			:insert(myPhase)
			:addSystem(function()
				expect(useDeltaTime()).toBeTruthy()
			end, myPhase)

		myScheduler:runAll()
	end)

	test("useThrottle", function()
		local matterHooks = require("@Plugins/planck_matter_hooks/src")
		local useThrottle = matterHooks.useThrottle
		expect.assertions(1)

		local plugin = matterHooks.Plugin.new()

		local myPhase = Phase.new("myPhase")
		local myScheduler = Scheduler.new(1, 2, 3)
			:addPlugin(plugin)
			:insert(myPhase)
			:addSystem(function()
				if useThrottle(1) then
					expect(true).toBe(true)
				end
			end, myPhase)

		myScheduler:runAll()
	end)
end)
