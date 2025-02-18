import { Scheduler } from "@rbxts/planck";

export class Plugin<T extends unknown[]> {
  build(scheduler: Scheduler<T>): void;
}

export function useDeltaTime(): number;
export function useEvent(): () => [];
export function useThrottle(seconds: number, discriminator?: unknown): boolean;
export function log(...args: unknown[]): void;
