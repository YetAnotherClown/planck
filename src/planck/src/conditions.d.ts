import { EventInstance, EventLike, ExtractEvents } from "./utils";

export type Condition<T extends unknown[] = unknown[]> = (...args: T) => boolean;

export const timePassed: (time: number) => Condition;

export const runOnce: () => Condition;

type ExtractEventArgs<T> = T extends EventLike<infer U> ? U : never;
type ExtractEvent<T extends EventInstance> = {
  [K in keyof T]: T[K] extends EventLike ? ExtractEventArgs<T[K]> : never;
};
type CollectEvents<T extends unknown[]> = () => IterableFunction<LuaTuple<[number, ...T]>>;
export function onEvent<T extends EventInstance, E extends ExtractEvents<T>>(
  instance: T,
  event: E
): LuaTuple<[hasNewEvent: Condition, collectEvents: CollectEvents<ExtractEvent<T>[E]>]>;
export function onEvent<T extends EventLike>(
  instance: EventInstance,
  event: T
): LuaTuple<[hasNewEvent: Condition, collectEvents: CollectEvents<ExtractEventArgs<T>>]>;
export function onEvent<T extends EventLike>(
  instance: T
): LuaTuple<[hasNewEvent: Condition, collectEvents: CollectEvents<ExtractEventArgs<T>>]>;

export const isNot: <T extends unknown[]>(fn: Condition<T>) => Condition<T>;
