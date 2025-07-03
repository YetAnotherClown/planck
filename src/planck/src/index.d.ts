import { Scheduler } from "./Scheduler";

export * from "./conditions";
export * from "./Phase";
export * from "./Pipeline";
export * from "./Scheduler";

export interface Plugin<T extends unknown[]> {
  build(scheduler: Scheduler<T>): void;
  cleanup?(): void;
  [key: string | number | symbol]: any;
}
