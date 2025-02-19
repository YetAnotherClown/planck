// Types sourced from Matter, a library by evaera (https://github.com/evaera)
// License: Copyright (c) 2021 Eryn L. K., MIT License
// Source: https://github.com/matter-ecs/matter-types/blob/master/lib/hooks/useEvent.d.ts
type ConnectionLike =
  | { Disconnect(): void }
  | { disconnect(): void }
  | { Destroy(): void }
  | { destroy(): void }
  | (() => void);

type SignalLike<Args extends Array<unknown>> =
  | { Connect(callback: (...args: Args) => void): ConnectionLike }
  | { connect(callback: (...args: Args) => void): ConnectionLike }
  | { on(callback: (...args: Args) => void): ConnectionLike };

type InferSignalParameters<T> = T extends SignalLike<infer U> ? U : never;

declare function useEvent<I extends Instance, E extends InstanceEventNames<I>>(
  instance: I,
  event: E
): IterableFunction<LuaTuple<[index: number, ...rest: InferSignalParameters<InstanceEvents<I>[E]>]>>;

declare function useEvent<A extends Array<unknown>, E extends SignalLike<A>>(
  discriminator: unknown,
  event: E
): IterableFunction<LuaTuple<[index: number, ...rest: InferSignalParameters<E>]>>;

export = useEvent;
