local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent.Parent

local Scheduler = require(root.Scheduler)
local conditions = require(root.conditions)

local isNot = conditions.isNot
local runOnce = conditions.runOnce
local timePassed = conditions.timePassed
local onEvent = conditions.onEvent

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

describe("conditions", function()
	test("isNot", function()
		expect.assertions(1)
		local function system()
			expect("Planckton!!!").toEqual(expect.anything())
		end

		local bool = false

		local function condition()
			return bool
		end

		local myScheduler = Scheduler.new()
			:addSystem(system)
			:addRunCondition(system, isNot(condition))

		myScheduler:runAll() -- Expect to run

		bool = true
		myScheduler:runAll() -- Expect to not run
	end)

	test("runOnce", function()
		expect.assertions(1)
		local function system()
			expect(true).toBe(true)
		end

		local myScheduler =
			Scheduler.new():addSystem(system):addRunCondition(system, runOnce())

		myScheduler:runAll() -- Expect to run
		myScheduler:runAll() -- Expect to not run
	end)

	test("timePassed", function()
		expect.assertions(3)
		local didRun = false
		local firstRun = false

		local function system()
			if firstRun then
				didRun = true
			end

			firstRun = true
		end

		local myScheduler = Scheduler.new()
			:addSystem(system)
			:addRunCondition(system, timePassed(1))

		myScheduler:runAll()
		expect(didRun).toBe(false)
		task.wait(0.5)

		myScheduler:runAll()
		expect(didRun).toBe(false)
		task.wait(0.5)

		myScheduler:runAll()
		expect(didRun).toBe(true)
	end)

	test("onEvent", function()
		expect.assertions(4)
		local didRun = false
		local bindableEvent = Instance.new("BindableEvent")

		local function system()
			didRun = true
		end

		local myScheduler = Scheduler.new():addSystem(system):addRunCondition(
			system,
			onEvent(bindableEvent, bindableEvent.Event)
		)

		myScheduler:runAll()
		expect(didRun).toBe(false)
		bindableEvent:Fire()
		task.wait()

		myScheduler:runAll()
		expect(didRun).toBe(true)
		didRun = false

		myScheduler:runAll()
		expect(didRun).toBe(false)
		bindableEvent:Fire()
		task.wait()

		myScheduler:runAll()
		expect(didRun).toBe(true)
	end)

	test("onEvent in SystemTable", function()
		expect.assertions(4)
		local didRun = false
		local bindableEvent = Instance.new("BindableEvent")

		local function system()
			didRun = true
		end

		local myScheduler = Scheduler.new():addSystem({
			system = system,
			runConditions = { onEvent(bindableEvent, bindableEvent.Event) },
		})

		myScheduler:runAll()
		expect(didRun).toBe(false)
		bindableEvent:Fire()
		task.wait()

		myScheduler:runAll()
		expect(didRun).toBe(true)
		didRun = false

		myScheduler:runAll()
		expect(didRun).toBe(false)
		bindableEvent:Fire()
		task.wait()

		myScheduler:runAll()
		expect(didRun).toBe(true)
	end)
end)
