local JestGlobals = require(script.Parent.Parent.Parent.Parent.DevPackages.JestGlobals)

local Planck = require(script.Parent.Parent.Parent.Planck)
local PlanckRunService = require(script.Parent.Parent)

local Phase = Planck.Phase
local Scheduler = Planck.Scheduler

local test = JestGlobals.test
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("Planck RunService", function()
	test("default phase works", function(_, done)
		expect.assertions(1)

		local function system()
			expect(true).toBe(true)
			done()
		end

		local runServicePlugin = PlanckRunService.Plugin.new()
		Scheduler.new()
			:addPlugin(runServicePlugin)
			:addSystem(system)
			:addRunCondition(system, Planck.runOnce())
	end)

	test("with startup phases", function(_, done)
		expect.assertions(2)

		local function system()
			expect(true).toBe(true)
			done()
		end

		local runServicePlugin = PlanckRunService.Plugin.new()
		Scheduler.new()
			:addPlugin(runServicePlugin)
			:addSystem(function()
				expect(true).toBe(true)
			end, Phase.Startup)
			:addSystem(system)
			:addRunCondition(system, Planck.runOnce())
	end)
end)
