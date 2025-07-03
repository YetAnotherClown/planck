import { Scheduler } from "@rbxts/planck";
import type { Plugin as PluginInterface } from "@rbxts/planck";

declare class Plugin<T extends unknown[]> implements PluginInterface<T> {
  build(scheduler: Scheduler<T>): void;
}

export = Plugin;
