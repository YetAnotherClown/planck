import { EventInstance, EventLike, ExtractEvents } from "./utils";

export type Condition<T extends unknown[] = unknown[]> = (
  ...args: T
) => boolean;

/**
 * A Throttle condition which checks whether the amount of
 * time given has passed or not.
 */
export const timePassed: (time: number) => Condition;

/** Checks whether the condition has been called once before. */
export const runOnce: () => Condition;

type ExtractEventArgs<T> = T extends EventLike<infer U> ? U : never;
type ExtractEvent<T extends EventInstance> = {
  [K in keyof T]: T[K] extends EventLike ? ExtractEventArgs<T[K]> : never;
};
type CollectEvents<T extends unknown[]> = () => IterableFunction<
  LuaTuple<[number, ...T]>
>;

/**
 * Checks for any new events and allows for the collection of those events.
 *
 * Read [OnEvent](https://yetanotherclown.github.io/planck/docs/design/conditions/#on-event) for more information.
 */
export function onEvent<T extends EventInstance, E extends ExtractEvents<T>>(
  instance: T,
  event: E
): LuaTuple<
  [hasNewEvent: Condition, collectEvents: CollectEvents<ExtractEvent<T>[E]>]
>;

/**
 * Checks for any new events and allows for the collection of those events.
 *
 * Read [OnEvent](https://yetanotherclown.github.io/planck/docs/design/conditions/#on-event) for more information.
 */
export function onEvent<T extends EventLike>(
  instance: EventInstance,
  event: T
): LuaTuple<
  [hasNewEvent: Condition, collectEvents: CollectEvents<ExtractEventArgs<T>>]
>;

/**
 * Checks for any new events and allows for the collection of those events.
 *
 * Read [OnEvent](https://yetanotherclown.github.io/planck/docs/design/conditions/#on-event) for more information.
 */
export function onEvent<T extends EventLike>(
  instance: T
): LuaTuple<
  [hasNewEvent: Condition, collectEvents: CollectEvents<ExtractEventArgs<T>>]
>;

/** Inverses a given condition. */
export const isNot: <T extends unknown[]>(
  fn: Condition<T>,
  ...any: any[]
) => Condition<T>;
