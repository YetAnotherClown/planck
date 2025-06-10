local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Planck = require(ReplicatedStorage.Packages.Planck)
local PlanckRunService = require(ReplicatedStorage.Packages.PlanckRunService)

local Phase = Planck.Phase
local Scheduler = Planck.Scheduler

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

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
