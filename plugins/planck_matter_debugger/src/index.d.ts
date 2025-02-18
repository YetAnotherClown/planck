import { Scheduler } from "@rbxts/planck";

declare class MatterDebuggerPlugin<T extends unknown[]> {
  build(scheduler: Scheduler<T>): void;
}
export = MatterDebuggerPlugin;
