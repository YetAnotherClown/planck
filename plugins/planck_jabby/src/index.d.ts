import { Scheduler } from "@rbxts/planck";

export default class Plugin<T extends unknown[]> {
  build(scheduler: Scheduler<T>): void;
}
