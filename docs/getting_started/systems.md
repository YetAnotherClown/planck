---
title: Systems
description: The basics of Systems
sidebar_position: 3
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

# Systems

Systems, at their very core, are functions that are designed to be execution on a certain event or on a loop.

When working with ECS on Roblox, typically you will have most of your systems running on the [RunService.Heartbeat](https://create.roblox.com/docs/reference/engine/classes/RunService#Heartbeat) event.
This will run your systems every *frame*, on the `Heartbeat`.

We will go over running systems on events later on. For now, let's see
how we create and add systems to the Scheduler.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua title="systemA.luau"
local function systemA()
    -- ...
end

return systemA
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="systemA.ts"
function systemA() {
    // ...
}

export = systemA;
```
</TabItem>
</Tabs>
This is how systems are typically made: a single function inside of a
ModuleScript.

To add this to our Scheduler, we can do:

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua title="scheduler.luau"
-- ...

local systemA = require("@shared/systems/systemA")

local scheduler = Scheduler.new(world, state)
    :addSystem(systemA)
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="scheduler.ts"
// ...

import systemA from "shared/systems/systemA";

const scheduler = new Scheduler(world, state)
    .addSystem(systemA);
```
</TabItem>
</Tabs>
Remember how we also passed state into the Scheduler to our Systems?
This will be passed directly into the parameters of our systems.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua {1} title="systemA.luau"
local function systemA(world, state)
    -- ...
end

return systemA
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts {1} title="systemA.ts"
function systemA(world: World, state: unknown) {
    // ...
}

export = systemA;
```
</TabItem>
</Tabs>
### System Tables

Another way you can define a System is with a SystemTable.

SystemTables contain not only the *function* but can also contain a Phase,
Name, and Run Condition for Systems.

| Field         | Type                    |              |
| ------------- | ----------------------- | ------------ |
| name          | string                  | Optional     |
| system        | function                | **Required** |
| phase         | Phase                   | Optional     |
| runConditions | \{ (...any) -> boolean \} | Optional     |

The Name is used for debugging and used in tooling such as Jabby to help you identify systems, this is automatically inferred from the function name, so it's completely optional.

Don't worry about what a Phase or Run Condition is for now, we will explain these later.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua title="systemA.luau"
local function systemA(world, state)
    -- ...
end

local function condition(world, state)
    if someCondition then
        return true
    else
        return false
    end
end

return {
    name = "systemA",
    system = systemA,
    phase = Planck.Phase.PreUpdate,
    runConditions = { condition }
}
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="systemA.ts"
function systemA(world: World, state: unknown) {
    // ...
}

function condition(world: World, state: unknown) {
    if (someCondition) {
        return true;
    } else {
        return false;
    }
}

export = {
    name: "systemA",
    system: systemA,
    phase: Phase.PreUpdate,
    runConditions: [ condition ],
};
```
</TabItem>
</Tabs>
And then we can add this the same way as the first example,

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua title="scheduler.luau"
-- ...

local systemA = require("@shared/systems/systemA")

local scheduler = Scheduler.new(world, state)
    :addSystem(systemA)
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="scheduler.ts"
// ...

import systemA from "shared/systems/systemA";

const scheduler = new Scheduler(world, state)
    .addSystem(systemA);
```
</TabItem>
</Tabs>
### System Sets

You can also create a set, or rather an array of Systems. These can either
be functions or SystemTables. You can even mix the two in a System Set.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
-- ...

local systemA = require("@shared/systems/systemA")
local systemB = require("@shared/systems/systemB")

local systemSet = { systemA, systemB }

local scheduler = Scheduler.new(world, state)
    :addSystems(systemSet)
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
// ...

import systemA from "shared/systems/systemA";
import systemB from "shared/systems/systemB";

const systemSet = [systemA, systemB];

const scheduler = new Scheduler(world, state)
    .addSystems(systemSet);
```
</TabItem>
</Tabs>
This allows us to bulk add systems to the Scheduler. When we learn about Phases, this will also allow us to bulk set what phase these systems run on.

### Initializer Systems

Sometimes you need to do one-time setup when a system first runs, like caching a query or creating a connection. Initializer systems let you do this by returning a function on their first execution.

```lua title="renderSystem.luau"
local function renderSystem(world, state)
    -- This runs once on first execution
    local renderables = world:query(Transform, Model)

    -- Return the function that runs on each subsequent execution
    return function(world, state)
        for id, transform, model in renderables do
            render(transform, model)
        end
    end
end

return renderSystem
```

The first time `renderSystem` runs, it creates the query and returns the runtime function, then immediately executes that runtime function. On all subsequent executions, only the returned function runs.

#### Cleanup

If your system needs to clean up resources (like connections), you can return a cleanup function too:

```lua title="networkSystem.luau"
local function networkSystem(world, state)
    local connection = Players.PlayerAdded:Connect(function(player)
        -- Handle player joining
    end)

    return function(world, state)
        -- Runtime logic
    end, function()
        -- Cleanup runs when system is removed
        connection:Disconnect()
    end
end

return networkSystem
```

The cleanup function will run automatically when you call `scheduler:removeSystem(networkSystem)`.

## What's Next?

Now that we have systems, we should learn how to properly manage their order
of execution. This is where Phases come in.

→ [Phases](./phases.md)