import { Scheduler } from "@rbxts/planck";

declare class JabbyPlugin<T extends unknown[]> {
  build(scheduler: Scheduler<T>): void;
}
export = JabbyPlugin;
