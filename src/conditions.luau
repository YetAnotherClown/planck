local utils = require("./utils")
local getConnectFunction = utils.getConnectFunction

type EventLike = utils.EventLike
type EventInstance = utils.EventInstance

type Condition = () -> boolean

--- @class Conditions
---
--- Conditions can be used in systems or as Run Conditions.

--- @within Conditions
--- @param time number -- Time in seconds
--- @return hasTimePassed () -> boolean
---
--- A Throttle condition which checks whether the amount of
--- time given has passed or not.
local function timePassed(time: number): Condition
	local storedTime

	return function()
		if storedTime == nil or os.clock() - storedTime >= time then
			storedTime = os.clock()
			return true
		end

		return false
	end
end

--- @within Conditions
--- @return hasRanOnce () -> boolean
---
--- Checks whether the condition has been called once before
local function runOnce(): Condition
	local hasRan = false

	return function()
		if not hasRan then
			hasRan = true
			return true
		end

		return false
	end
end

type CollectEvents<U...> = () -> () -> (number, U...)

--- @within Conditions
--- @return hasNewEvent () -> boolean
--- @return collectEvents () -> () -> (number, U...)
---
--- Checks for any new events and allows for the collection of
--- those events.
local function onEvent<U...>(
	instance: EventInstance | EventLike,
	event: string | EventLike
): (Condition, CollectEvents<U...>)
	local connect = getConnectFunction(instance, event)
	assert(connect, "Event passed to .onEvent is not valid")

	local newEvent = false
	local queue = {}

	local function callback(...)
		newEvent = true
		table.insert(queue, { ... })
	end

	connect(callback)

	local function hasNewEvent()
		if newEvent then
			newEvent = false
			return true
		end

		table.clear(queue)
		return false
	end

	local function collectEvents()
		local n = 0
		return function(): (number, U...)
			n += 1

			local args = table.remove(queue, 1)

			if args then
				return n, table.unpack(args)
			end

			return nil :: any
		end
	end

	return hasNewEvent, collectEvents
end

--- @within Conditions
--- @param condition () -> boolean
--- @return inverseCondition () -> boolean
---
--- Inverses a given condition.

-- selene: allow(unused_variable)
local function isNot(condition: Condition, ...: any): Condition
	return function()
		return not condition()
	end
end

return {
	timePassed = timePassed,
	runOnce = runOnce,
	onEvent = onEvent,
	isNot = isNot,
}
