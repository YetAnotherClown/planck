local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent.Parent

local Phase = require(root.Phase)
local Scheduler = require(root.Scheduler)

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

describe("topoRuntime", function()
	test("useDeltaTime", function()
		local matterHooks =
			require(ReplicatedStorage.Packages.PlanckMatterHooks)
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
		local matterHooks =
			require(ReplicatedStorage.Packages.PlanckMatterHooks)
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
