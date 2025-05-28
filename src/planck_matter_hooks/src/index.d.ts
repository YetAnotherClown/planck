import { Scheduler } from "@rbxts/planck";
import log from "./hooks/log";
import useDeltaTime from "./hooks/useDeltaTime";
import useEvent from "./hooks/useEvent";
import useThrottle from "./hooks/useThrottle";

export class Plugin<T extends unknown[]> {
  build(scheduler: Scheduler<T>): void;
}

export { log, useDeltaTime, useEvent, useThrottle };
