---
title: Conditions
description: Designing with Conditions
sidebar_position: 4
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

# Conditions

During the execution of your game's code, not everything needs to be
executed every frame. This is where conditions come in!

## Run Conditions

In Planck, we can assign *Run Conditions* to Systems, Phases, and Pipelines.
Run Conditions are very simple, they are just functions that return true or
false.

We can set a Run Condition on a System/Phase/Pipeline like so,

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local function condition(world)
    if someCondition then
        return true
    else
        return false
    end
end

local scheduler = Scheduler.new(world)
    :addRunCondition(systemA, condition)
    :addRunCondition(somePhase, condition)
    :addRunCondition(somePipeline, condition)
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
function condition(world: World) {
    if (someCondition) {
        return true;
    } else {
        return false;
    }
}

const scheduler = new Scheduler(world)
    .addRunCondition(systemA, condition)
    .addRunCondition(somePhase, condition)
    .addRunCondition(somePipeline, condition);
```
</TabItem>
</Tabs>
## Common Conditions

Planck provides several built-in conditions for you to use as
Run Conditions.

:::tip
Some conditions, like `onEvent` have secondary purposes.

You can use conditions themselves in systems, and conditions
like `onEvent` will also create a `collectEvents` function which
you can use to handle events inside of your systems.
:::

### Time Passed (Throttle)

Sometimes, we only want our systems to run on specific intervals. We can
use the `timePassed` condition:

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local Planck = require("@packages/Planck")

local Scheduler = Planck.Scheduler
local timePassed = Planck.timePassed

local scheduler = Scheduler.new(world)
    :addRunCondition(systemA, timePassed(10)) -- Run every 10 seconds
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Scheduler, timePassed } from "@rbxts/planck";

const scheduler = new Scheduler(world)
    .addRunCondition(systemA, timePassed(10)); // Run every 10 seconds
```
</TabItem>
</Tabs>
It's important to note that `systemA` will still be ran on
`RunService.Heartbeat`. Our time will tick up until it reaches the given
interval when the event fires again.

### Run Once

In Planck, we have Startup Phases built-in. You might want to recreate
something akin to these if you're not using the built-in Phases.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local Planck = require("@packages/Planck")

local Scheduler = Planck.Scheduler
local runOnce = Planck.runOnce

local scheduler = Scheduler.new(world)
    :addRunCondition(systemA, runOnce()) -- Run only once
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Scheduler, runOnce } from "@rbxts/planck";

const scheduler = new Scheduler(world)
    .addRunCondition(systemA, runOnce()); // Run only once
```
</TabItem>
</Tabs>

### On Event

We might want to run a system only when there are any new events since last
frame.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local Planck = require("@packages/Planck")

local Scheduler = Planck.Scheduler
local onEvent = Planck.onEvent

local scheduler = Scheduler.new(world)
    -- Run out system only when there is a new Player
    :addRunCondition(systemA, onEvent(Players.PlayerAdded))
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Scheduler, onEvent } from "@rbxts/planck";

const scheduler = new Scheduler(world)
    // Run out system only when there is a new Player
    .addRunCondition(systemA, onEvent(Players.PlayerAdded));
```
</TabItem>
</Tabs>
It is important to note that we don't actually collect the events using
this condition. You will have to do that yourself.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local Players = game:GetService("Players")

local Planck = require("@packages/Planck")

local onEvent = Planck.onEvent
local hasNewEvent, collectEvents = onEvent(Players.PlayerAdded)

local function systemA()
    for i, player in collectEvents() do
        -- Do something
    end
end

return {
    system = systemA,
    runConditions = { hasNewEvent }
}
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Players } from "@rbxts/services";
import { onEvent } from "@rbxts/planck";

const [hasNewEvent, collectEvents] = onEvent(Players.PlayerAdded);

function systemA() {
    for ([i, player] of collectEvents()) {
        // Do something
    }
}

export = {
    system: systemA,
    runConditions: [hasNewEvent],
}
```
</TabItem>
</Tabs>
:::tip[Cleaning Up Events]
If you would like to cleanup the event connection that the `onEvent` condition uses,
you can get the disconnect function like so.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local Planck = require("@packages/Planck")

local onEvent = Planck.onEvent
local hasNewEvent, collectEvents, getDisconnectFn = onEvent(Players.PlayerAdded)

local disconnect = getDisconnectFn()
disconnect() -- Event is no longer connected
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Scheduler, onEvent } from "@rbxts/planck";

const [hasNewEvent, collectEvents, getDisconnectFn] = onEvent(Players.PlayerAdded);

const disconnect = getDisconnectFn();
disconnect(); // Event is no longer connected
```
</TabItem>
</Tabs>
If you use `scheduler:removeSystem()` to remove a system, all of it's conditions
will be cleaned up with it, so long as the condition is not being used for any
other system, phase, or pipeline.
:::

#### Defining Events

`Planck.onEvent` supports many different ways of defining events. Some provide full typechecking,
while others don't.

| Types                     	|                                                	| Typechecked 	|
|---------------------------	|------------------------------------------------	|:-----------:	|
| RBXScriptSignal           	| `Planck.onEvent(Players.PlayerAdded)`          	|      ✓      	|
| Instance, RBXScriptSignal 	| `Planck.onEvent(Players, Players.PlayerAdded)` 	|      ✓      	|
| Instance, string          	| `Planck.onEvent(Players, "PlayerAdded")`       	|      ✕      	|
| SignalLike                	| `Planck.onEvent(mySignal)`                     	|      ✓      	|
| table, string             	| `Planck.onEvent(t, "connect")`                 	|      ✕      	|
| table, method             	| `Planck.onEvent(t, t.connect)`                 	|      ✓      	|
| function                  	| `Planck.onEvent(connect)`                      	|      ✓      	|

### Not

This is a really simple condition, it just inverses the condition passed.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local Planck = require("@packages/Planck")

local Scheduler = Planck.Scheduler
local onEvent = Planck.onEvent
local isNot = Planck.isNot

local scheduler = Scheduler.new(world)
    -- Run our system only on frames where there are no new Players
    :addRunCondition(systemA, isNot(onEvent(Players.PlayerAdded)))
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Scheduler, onEvent, isNot } from "@rbxts/planck";

const scheduler = new Scheduler(world)
    // Run our system only when there is a new Player
    .addRunCondition(systemA, isNot(onEvent(Players.PlayerAdded)[0]));
```
</TabItem>
</Tabs>
## Ideas for Conditions

### Player Alive

In Roblox, we typically have a Player with a Humanoid. It might make sense
to only run some systems when the Player is alive.

Here's a write up for what that might look like for a client system,

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
-- Player singleton
local LocalPlayer = world:component()
world:set(LocalPlayer, LocalPlayer)
world:set(LocalPlayer, Health, 100)

local function playerAlive()
    return function(world)
        local health = world:get(LocalPlayer, Health)

        if health > 0 then
            return true
        else
            return false
        end
    end
end

local scheduler = Scheduler.new(world)
    -- Run the system only when the Player is alive
    :addRunCondition(systemA, playerAlive())
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
const LocalPlayer = world.component();
world.set(LocalPlayer, LocalPlayer);
world.set(LocalPlayer, Health, 100);

function playerAlive() {
    return function (world: World) {
        const health = world.get(LocalPlayer, Health);

        if (health > 0) {
            return true;
        } else {
            return false;
        }
    };
}

const scheduler = new Scheduler(world)
    // Run the system only when the Player is alive
    .addRunCondition(systemA, playerAlive());
```
</TabItem>
</Tabs>

This helps us to avoid unnecessarily running systems that only have behavior
when the Player is alive.

## Run Conditions Are Not Dependencies

Your systems should *not* depend on conditions. In the context of your
system, it should not matter whether a Run Condition is true or false,
the system should work.

The purpose of Run Conditions are to minimize the amount of systems that
are running during a frame, by cutting out systems which do not need to
run in a given moment.
