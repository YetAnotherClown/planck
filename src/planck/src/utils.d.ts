export type EventLike<T extends unknown[] = unknown[]> =
  | RBXScriptSignal<(...args: T) => void>
  | { connect(listener: (...args: T) => void): unknown }
  | { Connect(listener: (...args: T) => void): unknown }
  | { on(listener: (...args: T) => void): unknown };
export type EventInstance = Instance | { [k: string]: EventLike };

export type ExtractEvents<T extends EventInstance> = {
  [K in keyof T]: T[K] extends EventLike ? K : never;
}[keyof T];
