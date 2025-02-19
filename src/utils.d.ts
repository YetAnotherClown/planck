export type EventLike<T extends unknown[] = unknown[]> =
  | RBXScriptSignal<(...args: T) => void>
  | { connect(...args: T): unknown }
  | { Connect(...args: T): unknown }
  | { on(...args: T): unknown };
export type EventInstance = Instance | { [k: string]: EventLike };

export type ExtractEvents<T extends EventInstance> = {
  [K in keyof T]: T[K] extends EventLike ? K : never;
}[keyof T];
