---
title: Matter
description: Suggested setup guide for Matter
sidebar_position: 1
---

Recommended project structure

<pre style={{lineHeight: "120%", width: "fit-content", "--ifm-paragraph-margin-bottom": 0}}>
    ReplicatedStorage/
    ├─ Packages/
    │  ├─ Matter.luau
    │  ├─ Planck.luau
    │  ├─ DebuggerPlugin.luau
    │  ├─ HooksPlugin.luau
    ├─ client/
    │  ├─ systems/
    ├─ shared/
    │  ├─ systems/
    │  ├─ components.luau
    │  ├─ scheduler.luau
    │  ├─ startup.luau
    │  ├─ world.luau
    <br />
    ServerScriptService/
    ├─ server/
    │  ├─ systems/
    │  ├─ server.server.luau
    <br />
    StarterPlayerScripts/
    ├─ client.client.luau
</pre>

```toml title="wally.toml"
[dependencies]
Matter = "matter-ecs/matter@0.8.4"
Planck = "yetanotherclown/planck@0.2.0"
PlanckMatterDebugger = "yetanotherclown/planck-matter-debugger@0.2.0"
PlanckMatterHooks = "yetanotherclown/planck-matter-hooks@0.2.1"
```

### Creating the World

First, we'll create a module called `world.luau` where we create and export our Matter World.

```lua title="ReplicatedStorage/shared/world.luau"
local Matter = require("@packages/Matter")
local World = Matter.World

local world = World.new()

return world
```

### Creating the Scheduler

Next, we'll create a module called `scheduler.luau` where we create and export our scheduler.

```lua title="ReplicatedStorage/shared/scheduler.luau"
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local scheduler = scheduler.new()

return scheduler
```

Then lets pass the world to our scheduler

```lua {4,6}title="ReplicatedStorage/shared/scheduler.luau"
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local world = require("@shared/world")

local scheduler = scheduler.new(world)

return scheduler
```

And then let's add our Hooks Plugin (we will add the Debugger plugin later)

```lua {6,7,10} title="ReplicatedStorage/shared/scheduler.luau"
local Matter = require("@packages/Matter")
local Plasma = require("@packages/Plasma")

local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local world = require("@shared/world")

local DebuggerPlugin = require("@packages/DebuggerPlugin")
local debuggerPlugin = DebuggerPlugin.new({ world })

local debugger = Matter.Debugger.new(Plasma)
local widgets = debugger:getWidgets()

local HooksPlugin = require("@packages/HooksPlugin")
local hooksPlugin = HooksPlugin.new()

local scheduler = scheduler.new(world, widgets)
    :addPlugin(hooksPlugin)
    :addPlugin(debuggerPlugin)

debugger:autoInitialize(debuggerPlugin:getLoop())

return scheduler
```

### Making Components

We'll store our Matter components in a `components.luau` module.

```lua title="ReplicatedStorage/shared/components.luau"
local Matter = require("@packages/Matter")

return {
    MyComponent = Matter.component("myComponent"),
}
```

### Creating Your First Systems

Let's create a basic system with Planck + Matter

In Startup systems, we can perform startup logic such as setting up
our initial entities, hence it running on the `Startup` phase.

```lua title="ReplicatedStorage/shared/systems/systemA.luau"
local Matter = require("@packages/Matter")

local Planck = require("@packages/Planck")
local Phase = Planck.Phase

local components = require("@shared/components")

local function systemA(world)
    -- Runs only once before all other Phases
end

return {
    system = systemA
    phase = Phase.Startup
}
```

To create a normal system, we do not need to provide a Phase.

```lua title="ReplicatedStorage/shared/systems/systemB.luau"
local function systemB(world)
    -- ...
end

return systemB
```

Notice how you can define systems as either a function or a table!

While you can set the phase directly in `Scheduler:addSystem(fn, phase)`,
it may be convenient to use a System Table instead.

:::note
Notice how we pass `world` into our system functions instead of requiring the
module we made.

We do this to keep systems pure, we avoid external dependencies by passing our
dependencies as function parameters. This makes our systems more testable and
reusable.
:::

### Your Startup Function

Your Startup function is where you first require the world and scheduler modules,
where you would add your systems to the scheduler, and where we will setup our Debugger.

```lua title="ReplicatedStorage/shared/startup.luau"
local scheduler = require("@shared/scheduler")
local world = require("@shared/world")

return function(systems)
    if #systems ~= 0 then
        scheduler:addSystems(systems) -- Assuming you're using SystemTables!
    end
end
```

### Server / Client Scripts

On the client, we'll add the `shared` and `client` systems.

```lua title="ReplicatedStorage/client/client.client.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local startup = require("@shared/startup")

local systems = {}

local function addSystems(folder)
    for _, system in folder:GetChildren() do
        if not system:IsA("ModuleScript") then
            continue
        end

        table.insert(systems, require(system))
    end
end

addSystems(ReplicatedStorage.shared.systems)
addSystems(ReplicatedStorage.client.systems)

startup(systems)
```

On the server, we'll instead add the `server` systems.

```lua {18} title="ServerScriptService/server/server.server.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local startup = require("@shared/startup")

local systems = {}

local function addSystems(folder)
    for _, system in folder:GetChildren() do
        if not system:IsA("ModuleScript") then
            continue
        end

        table.insert(systems, require(system))
    end
end

addSystems(ReplicatedStorage.shared.systems)
addSystems(ReplicatedStorage.server.systems)

startup(systems)
```
