--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent.Parent

local Phase = require(root.Phase)
local Scheduler = require(root.Scheduler)

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

describe("Initializer Systems", function()
	describe("Basic Initialization", function()
		test("standard system", function()
			expect.assertions(3)

			local runCount = 0

			local function standardSystem()
				runCount += 1
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(standardSystem, myPhase)

			myScheduler:runPhase(myPhase)
			expect(runCount).toBe(1)
			expect(myScheduler._systemInfo[standardSystem].initialized).toBe(
				true
			)

			myScheduler:runPhase(myPhase)
			expect(runCount).toBe(2)
		end)

		test("initializer system", function()
			expect.assertions(7)

			local initCount = 0
			local runCount = 0

			local function initializerSystem()
				initCount += 1

				return function()
					runCount += 1
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(initializerSystem, myPhase)

			myScheduler:runPhase(myPhase)
			expect(initCount).toBe(1)
			expect(runCount).toBe(0)
			expect(myScheduler._systemInfo[initializerSystem].initialized).toBe(
				true
			)

			myScheduler:runPhase(myPhase)
			expect(initCount).toBe(1)
			expect(runCount).toBe(1)

			myScheduler:runPhase(myPhase)
			expect(initCount).toBe(1)
			expect(runCount).toBe(2)
		end)

		test("initializer with cleanup", function()
			expect.assertions(5)

			local initCount = 0
			local runCount = 0
			local cleanupCount = 0

			local function initializerWithCleanup()
				initCount += 1

				return function()
					runCount += 1
				end, function()
					cleanupCount += 1
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler
				:insert(myPhase)
				:addSystem(initializerWithCleanup, myPhase)

			myScheduler:runPhase(myPhase)
			expect(initCount).toBe(1)
			expect(runCount).toBe(0)
			expect(myScheduler._systemInfo[initializerWithCleanup].cleanup).toBeTruthy()

			myScheduler:runPhase(myPhase)
			expect(runCount).toBe(1)

			myScheduler:removeSystem(initializerWithCleanup)
			expect(cleanupCount).toBe(1)
		end)

		test("init once", function()
			expect.assertions(2)

			local initCount = 0
			local runCount = 0

			local function initOnceSystem()
				initCount += 1
				return function()
					runCount += 1
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(initOnceSystem, myPhase)

			myScheduler:runPhase(myPhase)
			myScheduler:runPhase(myPhase)
			myScheduler:runPhase(myPhase)
			myScheduler:runPhase(myPhase)

			expect(initCount).toBe(1)
			expect(runCount).toBe(3)
		end)
	end)

	describe("Error Cases", function()
		test("invalid return type", function()
			expect.assertions(4)

			local attemptCount = 0

			local function brokenSystem()
				attemptCount += 1
				return "invalid"
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(brokenSystem, myPhase)

			myScheduler:runPhase(myPhase)
			expect(myScheduler._systemInfo[brokenSystem].initialized).toBe(
				false
			)
			expect(attemptCount).toBe(1)

			myScheduler:runPhase(myPhase)
			expect(myScheduler._systemInfo[brokenSystem].initialized).toBe(
				false
			)
			expect(attemptCount).toBe(2)
		end)

		test("retry failed init", function()
			expect.assertions(6)

			local shouldFail = true
			local initCount = 0
			local runCount = 0

			local function retryableSystem()
				initCount += 1
				if shouldFail then
					return 123
				else
					return function()
						runCount += 1
					end
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(retryableSystem, myPhase)

			myScheduler:runPhase(myPhase)
			expect(myScheduler._systemInfo[retryableSystem].initialized).toBe(
				false
			)
			expect(initCount).toBe(1)

			shouldFail = false

			myScheduler:runPhase(myPhase)
			expect(myScheduler._systemInfo[retryableSystem].initialized).toBe(
				true
			)
			expect(initCount).toBe(2)
			expect(runCount).toBe(0)

			myScheduler:runPhase(myPhase)
			expect(runCount).toBe(1)
		end)

		test("init with run condition", function()
			expect.assertions(5)

			local initCount = 0
			local runCount = 0
			local allowRun = false

			local function conditionalInit()
				initCount += 1
				return function()
					runCount += 1
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler
				:insert(myPhase)
				:addSystem(conditionalInit, myPhase)
				:addRunCondition(conditionalInit, function()
					return allowRun
				end)

			myScheduler:runPhase(myPhase)
			expect(initCount).toBe(0)
			expect(runCount).toBe(0)

			allowRun = true

			myScheduler:runPhase(myPhase)
			expect(initCount).toBe(1)
			expect(runCount).toBe(0)

			myScheduler:runPhase(myPhase)
			expect(runCount).toBe(1)
		end)

		test("nested initializer should not run inner", function()
			expect.assertions(3)

			local initCount = 0
			local runtimeReturnCount = 0
			local innerRunCount = 0

			local function nestedInit()
				initCount += 1
				return function()
					runtimeReturnCount += 1
					return function()
						innerRunCount += 1
					end
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(nestedInit, myPhase)

			myScheduler:runPhase(myPhase)
			myScheduler:runPhase(myPhase)
			myScheduler:runPhase(myPhase)

			expect(initCount).toBe(1)
			expect(runtimeReturnCount).toBe(2)
			expect(innerRunCount).toBe(0)
		end)

		test("nil with second value", function()
			expect.assertions(1)

			local function invalidNilSystem()
				return nil, "oops"
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(invalidNilSystem, myPhase)

			myScheduler:runPhase(myPhase)
			expect(myScheduler._systemInfo[invalidNilSystem].initialized).toBe(
				false
			)
		end)

		test("same system in multiple phases", function()
			expect.assertions(2)

			local initCount = 0

			local function sharedSystem()
				initCount += 1
				return function() end
			end

			local myScheduler = Scheduler.new()
			local phase1 = Phase.new("Phase1")
			local phase2 = Phase.new("Phase2")

			myScheduler
				:insert(phase1)
				:insert(phase2)
				:addSystem(sharedSystem, phase1)
				:addSystem(sharedSystem, phase2)

			myScheduler:runPhase(phase1)
			expect(initCount).toBe(1)

			myScheduler:runPhase(phase2)
			expect(initCount).toBe(1)
		end)

		test("table with 2 functions", function()
			expect.assertions(4)

			local initCount = 0
			local runCount = 0
			local cleanupCount = 0

			local function tableStyleInit()
				initCount += 1
				return {
					system = function()
						runCount += 1
					end,
					cleanup = function()
						cleanupCount += 1
					end,
				}
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(tableStyleInit, myPhase)

			myScheduler:runPhase(myPhase)
			expect(initCount).toBe(1)
			expect(runCount).toBe(0)

			myScheduler:runPhase(myPhase)
			expect(runCount).toBe(1)

			myScheduler:removeSystem(tableStyleInit)
			expect(cleanupCount).toBe(1)
		end)

		test("table with 1 function", function()
			expect.assertions(3)

			local initCount = 0
			local runCount = 0

			local function singleTableInit()
				initCount += 1
				return {
					system = function()
						runCount += 1
					end,
				}
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(singleTableInit, myPhase)

			myScheduler:runPhase(myPhase)
			expect(initCount).toBe(1)
			expect(runCount).toBe(0)

			myScheduler:runPhase(myPhase)
			expect(runCount).toBe(1)
		end)

		test("table with non-functions", function()
			expect.assertions(1)

			local function invalidTableSystem()
				return { system = "not a function", cleanup = 123 }
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(invalidTableSystem, myPhase)

			myScheduler:runPhase(myPhase)
			expect(myScheduler._systemInfo[invalidTableSystem].initialized).toBe(
				false
			)
		end)

		test("table with cleanup only (startup system)", function()
			expect.assertions(5)

			local startupRunCount = 0
			local cleanupRan = false

			local function startupSystem()
				startupRunCount += 1
				-- Returns cleanup only - no runtime system
				return {
					cleanup = function()
						cleanupRan = true
					end,
				}
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(startupSystem, myPhase)

			-- First run: startup logic executes
			myScheduler:runPhase(myPhase)
			expect(startupRunCount).toBe(1)
			expect(myScheduler._systemInfo[startupSystem].initialized).toBe(true)

			-- Second run: original function runs again (startup-only pattern)
			myScheduler:runPhase(myPhase)
			expect(startupRunCount).toBe(2)

			-- Cleanup on removal
			expect(cleanupRan).toBe(false)
			myScheduler:removeSystem(startupSystem)
			expect(cleanupRan).toBe(true)
		end)

		test("table with neither system nor cleanup", function()
			expect.assertions(1)

			local function invalidSystem()
				return { foo = "bar" } -- No system or cleanup fields
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(invalidSystem, myPhase)

			myScheduler:runPhase(myPhase)
			expect(myScheduler._systemInfo[invalidSystem].initialized).toBe(false)
		end)
	end)

	describe("Cleanup", function()
		test("cleanup once", function()
			expect.assertions(1)

			local cleanupCount = 0

			local function systemWithCleanup()
				return function() end, function()
					cleanupCount += 1
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(systemWithCleanup, myPhase)

			myScheduler:runPhase(myPhase)
			myScheduler:removeSystem(systemWithCleanup)

			expect(cleanupCount).toBe(1)
		end)

		test("no cleanup if uninitialized", function()
			expect.assertions(1)

			local cleanupCount = 0
			local allowRun = false

			local function conditionalSystem()
				return function() end, function()
					cleanupCount += 1
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler
				:insert(myPhase)
				:addSystem(conditionalSystem, myPhase)
				:addRunCondition(conditionalSystem, function()
					return allowRun
				end)

			myScheduler:runPhase(myPhase)

			myScheduler:removeSystem(conditionalSystem)
			expect(cleanupCount).toBe(0)
		end)

		test("cleanup failure", function()
			expect.assertions(2)

			local cleanupRan = false

			local function brokenCleanupSystem()
				return function() end, function()
					cleanupRan = true
					error("Cleanup failed!")
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler:insert(myPhase):addSystem(brokenCleanupSystem, myPhase)

			myScheduler:runPhase(myPhase)

			myScheduler:removeSystem(brokenCleanupSystem)

			expect(cleanupRan).toBe(true)
			expect(myScheduler._systemInfo[brokenCleanupSystem]).toBeNil()
		end)
	end)

	describe("Integration", function()
		test("with ordering", function()
			expect.assertions(4)

			local order = {}

			local function systemA()
				table.insert(order, "A-init")
				return function()
					table.insert(order, "A-run")
				end
			end

			local function systemB()
				table.insert(order, "B-init")
				return function()
					table.insert(order, "B-run")
				end
			end

			local myScheduler = Scheduler.new()
			local myPhase = Phase.new("myPhase")

			myScheduler
				:insert(myPhase)
				:addSystem(systemA, myPhase)
				:addSystem(systemB, myPhase)

			myScheduler:runPhase(myPhase)
			expect(order[1]).toBe("A-init")
			expect(order[2]).toBe("B-init")

			table.clear(order)

			myScheduler:runPhase(myPhase)
			expect(order[1]).toBe("A-run")
			expect(order[2]).toBe("B-run")
		end)

		test("with dependency graph", function()
			expect.assertions(4)

			local order = {}

			local function systemA()
				table.insert(order, "A-init")
				return function()
					table.insert(order, "A-run")
				end
			end

			local function systemB()
				table.insert(order, "B-init")
				return function()
					table.insert(order, "B-run")
				end
			end

			local myScheduler = Scheduler.new()
			local phaseA = Phase.new("PhaseA")
			local phaseB = Phase.new("PhaseB")

			myScheduler
				:insert(phaseA)
				:insertAfter(phaseB, phaseA)
				:addSystem(systemA, phaseA)
				:addSystem(systemB, phaseB)

			myScheduler:runPhase(phaseA)
			myScheduler:runPhase(phaseB)

			expect(order[1]).toBe("A-init")
			expect(order[2]).toBe("B-init")

			table.clear(order)

			myScheduler:runPhase(phaseA)
			myScheduler:runPhase(phaseB)

			expect(order[1]).toBe("A-run")
			expect(order[2]).toBe("B-run")
		end)
	end)
end)
