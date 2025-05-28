import { Scheduler } from "@rbxts/planck";

declare class MatterDebuggerPlugin<T extends unknown[]> {
  getLoop(): any;
  build(scheduler: Scheduler<T>): void;
}
export = MatterDebuggerPlugin;
