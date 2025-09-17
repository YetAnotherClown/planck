---
title: Matter
description: Suggested setup guide for Matter
sidebar_position: 1
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

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

<Tabs groupId="package-manager">
<TabItem value="wally" label="Wally">
```toml title="wally.toml"
[dependencies]
Matter = "matter-ecs/matter@0.8.4"
Planck = "yetanotherclown/planck@0.2.0"
PlanckMatterDebugger = "yetanotherclown/planck-matter-debugger@0.2.0"
PlanckMatterHooks = "yetanotherclown/planck-matter-hooks@0.2.1"
```
</TabItem>
<TabItem value="npm" label="NPM">
Run `npm i @rbxts/matter @rbxts/planck @rbxts/planck-matter-debugger @rbxts/planck-matter-hooks` in your terminal.
</TabItem>
</Tabs>

### Creating the World

First, we'll create a module called `world.luau` where we create and export our Matter World.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua title="ReplicatedStorage/shared/world.luau"
local Matter = require("@packages/Matter")
local World = Matter.World

local world = World.new()

return world
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="ReplicatedStorage/shared/world.ts"
import { World } from "@rbxts/matter";

const world = new World();

export default world;
```
</TabItem>
</Tabs>

### Creating the Scheduler

Next, we'll create a module called `scheduler.luau` where we create and export our scheduler.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua title="ReplicatedStorage/shared/scheduler.luau"
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local scheduler = Scheduler.new()

return scheduler
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="ReplicatedStorage/shared/scheduler.ts"
import { Scheduler } from "@rbxts/planck";

const scheduler = new Scheduler();

export default scheduler;
```
</TabItem>
</Tabs>

Then lets pass the world to our scheduler

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua {4,6} title="ReplicatedStorage/shared/scheduler.luau"
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local world = require("@shared/world")

local scheduler = Scheduler.new(world)

return scheduler
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts {3,5} title="ReplicatedStorage/shared/scheduler.ts"
import { Scheduler } from "@rbxts/planck";

import world from "shared/world";

const scheduler = new Scheduler(world);

export default scheduler;
```
</TabItem>
</Tabs>

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
And then let's add our Hooks Plugin, as well as the Debugger plugin

```lua {7-10,15-16,19-20} title="ReplicatedStorage/shared/scheduler.luau"
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
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts {7-8,13-14,17-18} title="ReplicatedStorage/shared/scheduler.ts"
import { Debugger } from "@rbxts/matter-debugger";
import Plasma from "@rbxts/plasma";
import { Scheduler } from "@rbxts/planck";

import world from "shared/world";

import DebuggerPlugin from "@rbxts/planck-matter-debugger";
const debuggerPlugin = new DebuggerPlugin([world]);

const debugger = new Debugger(Plasma);
const widgets = debugger.getWidgets();

import { Plugin as MatterHooks } from "@rbxts/planck-matter-hooks";
const hooksPlugin = new MatterHooks();

const scheduler = new Scheduler(world, widgets)
    .addPlugin(hooksPlugin)
    .addPlugin(debuggerPlugin);


const debuggerPlugin = new DebuggerPlugin({ world });

debugger.autoInitialize(debuggerPlugin.getLoop());

export default scheduler;
```
</TabItem>
</Tabs>
### Making Components

We'll store our Matter components in a `components.luau` module.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua title="ReplicatedStorage/shared/components.luau"
local Matter = require("@packages/Matter")

return {
    MyComponent = Matter.component("myComponent"),
}
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="ReplicatedStorage/shared/components.ts"
import { component } from "@rbxts/matter";

export const MyComponent = component("myComponent");
```
</TabItem>
</Tabs>
### Creating Your First Systems

Let's create a basic system with Planck + Matter

In Startup systems, we can perform startup logic such as setting up
our initial entities, hence it running on the `Startup` phase.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
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
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="ReplicatedStorage/shared/systems/systemA.ts"
import { component } from "@rbxts/matter";

import { Phase } from "@rbxts/planck";

import { MyComponent } from "shared/components";

function systemA(world: World) {
    // Runs only once before all other Phases
}

export = {
    system: systemA,
    phase: Phase.Startup,
};
```
</TabItem>
</Tabs>
To create a normal system, we do not need to provide a Phase.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua title="ReplicatedStorage/shared/systems/systemB.luau"
local function systemB(world)
    -- ...
end

return systemB
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="ReplicatedStorage/shared/systems/systemB.ts"
function systemB(world: World) {
    // ...
}

export = systemB;
```
</TabItem>
</Tabs>
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

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua title="ReplicatedStorage/shared/startup.luau"
local scheduler = require("@shared/scheduler")
local world = require("@shared/world")

return function(systems)
    if #systems ~= 0 then
        scheduler:addSystems(systems) -- Assuming you're using SystemTables!
    end
end
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="ReplicatedStorage/shared/startup.ts"
import { Scheduler } from "@rbxts/planck";

import world from "shared/world";
import scheduler from "shared/scheduler";

export default function startup(systems: System<[World]>[]) {
    if (systems.size() !== 0) {
        scheduler.addSystems(systems); // Assuming you're using SystemTables!
    }
};
```
</TabItem>
</Tabs>
### Server / Client Scripts

On the client, we'll add the `shared` and `client` systems.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
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
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="ReplicatedStorage/client/client.client.ts"
const ReplicatedStorage = game.GetService("ReplicatedStorage");

import startup from "shared/startup";

const systems: System<[World]>[] = [];

function addSystems(folder: Instance) {
    for (const system of folder:GetChildren()) {
        if (!system.isA("ModuleScript")) {
            continue;
        }

        systems.push(require(system));
    }
}

addSystems(ReplicatedStorage.FindFirstChild("shared")!.FindFirstChild("systems")!);
addSystems(ReplicatedStorage.FindFirstChild("client")!.FindFirstChild("systems")!);

startup(systems);
```
</TabItem>
</Tabs>
On the server, we'll instead add the `server` systems.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
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
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts {18} title="ServerScriptService/server/server.server.ts"
const ReplicatedStorage = game.GetService("ReplicatedStorage");

import startup from "shared/startup";

const systems: System<[World]>[] = [];

function addSystems(folder: Instance) {
    for (const system of folder:GetChildren()) {
        if (!system.isA("ModuleScript")) {
            continue;
        }

        systems.push(require(system));
    }
}

addSystems(ReplicatedStorage.FindFirstChild("shared")!.FindFirstChild("systems")!);
addSystems(ReplicatedStorage.FindFirstChild("server")!.FindFirstChild("systems")!);

startup(systems);
```
</TabItem>
</Tabs>
