export function elapsed(fun) {
  const start = globalThis.performance.now();
  const ret = fun();
  const stop = globalThis.performance.now();

  return [ret, (stop - start) * 1000000];
}
