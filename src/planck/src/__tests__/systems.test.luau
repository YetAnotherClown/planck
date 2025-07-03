local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent.Parent

local Phase = require(root.Phase)
local Scheduler = require(root.Scheduler)

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

describe("systems", function()
	test("add", function()
		expect.assertions(1)

		local myPhase = Phase.new("myPhase")
		local myScheduler = Scheduler.new(1, 2, 3)
			:insert(myPhase)
			:addSystem(function(...)
				expect({ ... }).toEqual({ 1, 2, 3 })
			end, myPhase)

		myScheduler:runAll()
	end)

	test("edit", function()
		expect.assertions(2)

		local function systemA(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler =
			Scheduler.new(1, 2, 3):insert(myPhase):addSystem(systemA, myPhase)

		myScheduler:runAll()

		local otherPhase = Phase.new()
		myScheduler:insert(otherPhase)

		myScheduler:editSystem(systemA, otherPhase)
		myScheduler:run(otherPhase)

		-- Expect nothing to run here
		myScheduler:run(myPhase)
	end)

	test("remove", function()
		expect.assertions(1)

		local function systemA(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler =
			Scheduler.new(1, 2, 3):insert(myPhase):addSystem(systemA, myPhase)

		myScheduler:runAll()

		myScheduler:removeSystem(systemA)
		myScheduler:runAll() -- Expect nothing here
	end)

	test("replace", function()
		expect.assertions(3)

		local function systemA(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local function systemB(...)
			-- FUTURE: Use Jest.spyOn
			expect(true).toBe(true)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler =
			Scheduler.new(1, 2, 3):insert(myPhase):addSystem(systemA, myPhase)

		myScheduler:runAll()

		myScheduler:replaceSystem(systemA, systemB)
		myScheduler:runAll()
	end)

	test("system table", function()
		expect.assertions(1)

		local myPhase = Phase.new("myPhase")

		local system = {
			system = function(...)
				expect({ ... }).toEqual({ 1, 2, 3 })
			end,
			phase = myPhase,
		}

		local myScheduler =
			Scheduler.new(1, 2, 3):insert(myPhase):addSystem(system)

		myScheduler:run(myPhase)
	end)

	test("run condition", function()
		expect.assertions(1)

		local bool = true

		local system = function(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler = Scheduler.new(1, 2, 3)
			:insert(myPhase)
			:addSystem(system, myPhase)
			:addRunCondition(system, function()
				return bool
			end)

		myScheduler:runAll()

		bool = false
		myScheduler:runAll() -- Expect system to not run
	end)

	test("multiple run conditions", function()
		expect.assertions(1)

		local firstCondition = true
		local secondCondition = true

		local system = function(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler = Scheduler.new(1, 2, 3)
			:insert(myPhase)
			:addSystem(system, myPhase)
			:addRunCondition(system, function()
				return firstCondition
			end)
			:addRunCondition(system, function()
				return secondCondition
			end)

		firstCondition = false
		myScheduler:runAll()

		firstCondition = true
		secondCondition = false
		myScheduler:runAll()

		firstCondition = false
		secondCondition = false
		myScheduler:runAll()

		firstCondition = true
		secondCondition = true
		myScheduler:runAll() -- Expect to run
	end)

	test("yield", function()
		expect.assertions(1)

		local system = function()
			wait(5)
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler =
			Scheduler.new(1, 2, 3):insert(myPhase):addSystem(system, myPhase)

		local err;

		(myScheduler :: any):_addHook(
			(myScheduler :: any).Hooks.SystemError,
			function(args)
				err = args.error
			end
		)

		myScheduler:runAll()
		expect(err).toEqual(expect.stringContaining("System yielded"))
	end)
end)
