export type EventLike =
  | RBXScriptSignal
  | {
      connect(...args: unknown[]): unknown;
    }
  | {
      Connect(...args: unknown[]): unknown;
    }
  | {
      on(...args: unknown[]): unknown;
    };
export type EventInstance =
  | Instance
  | {
      [k: string]: EventLike;
    };

export type ExtractEvents<T extends EventInstance> = {
  [K in keyof T]: T[K] extends EventLike ? K : never;
}[keyof T];
