--!nonstrict
local RunService = game:GetService("RunService")

local JestGlobals = require("@DevPackages/JestGlobals")

local Planck = require("@Project")

local Phase = Planck.Phase
local Pipeline = Planck.Pipeline
local Scheduler = Planck.Scheduler

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

describe("scheduler", function()
	describe("insert", function()
		test("phase", function()
			local myPhase = Phase.new("myPhase")
			local myScheduler = Scheduler.new():insert(myPhase)

			local orderedPhases =
				myScheduler._defaultDependencyGraph:getOrderedList()
			local mainIndex =
				table.find(orderedPhases, myScheduler._defaultPhase)

			expect(orderedPhases[mainIndex - 1]).toBe(myPhase)
		end)

		test("phase with event", function()
			local myPhase = Phase.new("myPhase")

			local myScheduler = Scheduler.new()
				:insert(myPhase, RunService, "Heartbeat")

			local identifier = `{RunService}@Heartbeat`
			local dependencyGraph =
				myScheduler._eventDependencyGraphs[identifier]

			expect(dependencyGraph).toBeTruthy()
			expect(myScheduler._connectedEvents[identifier]).toBeTruthy()

			local orderedList = dependencyGraph:getOrderedList()
			expect(orderedList[#orderedList]).toBe(myPhase)
		end)

		test("pipeline", function()
			local myPhase = Phase.new()
			local otherPhase = Phase.new()

			local myPipeline =
				Pipeline.new("myPipeline"):insert(myPhase):insert(otherPhase)

			local myScheduler = Scheduler.new():insert(myPipeline)

			local orderedDependencies =
				myScheduler._defaultDependencyGraph:getOrderedList()
			local mainIndex =
				table.find(orderedDependencies, myScheduler._defaultPhase)

			expect(orderedDependencies[mainIndex - 1]).toBe(myPipeline)

			local orderedPhases = myPipeline.dependencyGraph:getOrderedList()
			expect(orderedPhases[1]).toBe(myPhase)
			expect(orderedPhases[2]).toBe(otherPhase)
		end)

		test("pipeline with event", function()
			local myPhase = Phase.new()
			local otherPhase = Phase.new()

			local myPipeline =
				Pipeline.new("myPipeline"):insert(myPhase):insert(otherPhase)

			local myScheduler = Scheduler.new()
				:insert(myPipeline, RunService, "Heartbeat")

			local identifier = `{RunService}@Heartbeat`
			local dependencyGraph =
				myScheduler._eventDependencyGraphs[identifier]

			expect(dependencyGraph).toBeTruthy()
			expect(myScheduler._connectedEvents[identifier]).toBeTruthy()

			local orderedList = dependencyGraph:getOrderedList()
			expect(orderedList[1]).toBe(myPipeline)

			local orderedPhases = myPipeline.dependencyGraph:getOrderedList()
			expect(orderedPhases[1]).toBe(myPhase)
			expect(orderedPhases[2]).toBe(otherPhase)
		end)
	end)

	describe("insertAfter", function()
		test("phase", function()
			local phaseOne = Phase.new("phaseOne")
			local phaseTwo = Phase.new("phaseTwo")
			local phaseThree = Phase.new("phaseThree")

			local myScheduler = Scheduler.new()
				:insert(phaseOne)
				:insert(phaseTwo)
				:insertAfter(phaseThree, phaseOne)

			local orderedPhases =
				myScheduler._defaultDependencyGraph:getOrderedList()
			local mainIndex =
				table.find(orderedPhases, myScheduler._defaultPhase)

			expect(orderedPhases[mainIndex - 3]).toBe(phaseOne)
			expect(orderedPhases[mainIndex - 2]).toBe(phaseTwo)
			expect(orderedPhases[mainIndex - 1]).toBe(phaseThree)
		end)

		test("pipeline", function()
			local phaseOne = Phase.new("phaseOne")
			local phaseTwo = Phase.new("phaseTwo")
			local phaseThree = Phase.new("phaseThree")
			local phaseFour = Phase.new("phaseFour")

			local pipelineOne = Pipeline.new():insert(phaseOne):insert(phaseTwo)
			local pipelineTwo = Pipeline.new():insert(phaseFour)
			local pipelineThree = Pipeline.new():insert(phaseThree)

			local myScheduler = Scheduler.new()
				:insert(pipelineOne)
				:insert(pipelineTwo)
				:insertAfter(pipelineThree, pipelineOne)

			local orderedDependencies =
				myScheduler._defaultDependencyGraph:getOrderedList()
			local mainIndex =
				table.find(orderedDependencies, myScheduler._defaultPhase)

			expect(orderedDependencies[mainIndex - 3]).toBe(pipelineOne)
			expect(orderedDependencies[mainIndex - 2]).toBe(pipelineTwo)
			expect(orderedDependencies[mainIndex - 1]).toBe(pipelineThree)
		end)
	end)

	test("phase run condition", function()
		expect.assertions(1)

		local bool = true

		local system = function(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler = Scheduler.new(1, 2, 3)
			:insert(myPhase)
			:addSystem(system, myPhase)
			:addRunCondition(myPhase, function()
				return bool
			end)

		myScheduler:runAll()

		bool = false
		myScheduler:runAll() -- Expect system to not run
	end)

	test("pipeline run condition", function()
		expect.assertions(1)

		local bool = true

		local system = function(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")

		local myPipeline = Pipeline.new():insert(myPhase)

		local myScheduler = Scheduler.new(1, 2, 3)
			:insert(myPipeline)
			:addSystem(system, myPhase)
			:addRunCondition(myPipeline, function()
				return bool
			end)

		myScheduler:run(myPipeline)

		bool = false
		myScheduler:run(myPipeline) -- Expect system to not run
	end)

	test("getDeltaTime", function()
		local deltaTime

		local myScheduler = Scheduler.new()

		local system = function()
			deltaTime = myScheduler:getDeltaTime()
		end

		myScheduler:addSystem(system)
		myScheduler:run(system)
		expect(deltaTime).toEqual(0)
		myScheduler:run(system)
		expect(deltaTime).never.toEqual(0)
	end)

	describe("startup systems", function()
		test("should run once", function()
			expect.assertions(1)

			local myScheduler = Scheduler.new(1, 2, 3):addSystem(function(...)
				expect({ ... }).toEqual({ 1, 2, 3 })
			end, Phase.Startup)

			myScheduler:runAll()
			myScheduler:runAll()
		end)

		test("run before events once", function()
			expect.assertions(1)

			local myPhase = Phase.new("myPhase")
			local bindableEvent = Instance.new("BindableEvent")

			Scheduler.new(1, 2, 3)
				:addSystem(function(...)
					expect({ ... }).toEqual({ 1, 2, 3 })
				end, Phase.Startup)
				:insert(myPhase, bindableEvent, bindableEvent.Event)

			bindableEvent:Fire()
			task.wait()
			bindableEvent:Fire()
			task.wait()
		end)

		test("each run exactly once", function(_, done)
			expect.assertions(3)

			local myPhase = Phase.new("myPhase")
			local bindableEvent = Instance.new("BindableEvent")

			local n = 0
			local ranOnce = false

			Scheduler.new()
				:addSystem(function()
					n += 1
					expect(n).toEqual(1)
				end, Phase.PreStartup)
				:addSystem(function()
					n += 1
					expect(n).toEqual(2)
				end, Phase.Startup)
				:addSystem(function()
					n += 1
					expect(n).toEqual(3)
				end, Phase.PostStartup)
				:insert(myPhase, bindableEvent, bindableEvent.Event)
				:addSystem(function()
					if ranOnce then
						done()
					end

					ranOnce = true
				end, myPhase)

			bindableEvent:Fire()
			task.wait()
			bindableEvent:Fire()
			task.wait()
		end)
	end)
end)
