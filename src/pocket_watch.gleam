import gleam/io

import humanise

import pocket_watch/ffi
import pocket_watch/summary

/// Log time taken using a default callback with `io.println_error`.
///
/// ## Examples:
/// ```
/// {
///   use <- pocket_watch.simple("test")
///
///   process.sleep(1000)
/// } // pocket_watch [test]: took 1.0s
/// ```
pub fn simple(label: String, body: fn() -> a) -> a {
  let fun = fn(elapsed) {
    io.println_error("pocket_watch [" <> label <> "]: took " <> elapsed)
  }

  callback(fun, body)
}

/// Log time taken using a provided callback.
///
/// ## Examples:
/// ```
/// let print_time = fn(label, elapsed) { io.println_error(label <> " took " <> elapsed) }
///
/// {
///   use <- pocket_watch.callback(print_time("test", _))
///
///   process.sleep(1000)
/// } // test took 1.0s
/// ```
pub fn callback(with callback: fn(String) -> _, time body: fn() -> a) -> a {
  let callback = fn(elapsed) { callback(humanise.nanoseconds_float(elapsed)) }

  callback_ns(callback, body)
}

/// Log time taken using a provided callback that takes `Float` nanoseconds as argument.
///
/// ## Examples:
/// ```
/// let print_time = fn(label, elapsed) {
///   io.println_error(label <> " took " <> float.to_string(elapsed /. 1_000_000.0) <> "ms")
/// }
///
/// {
///   use <- pocket_watch.callback(print_time("test", _))
///
///   process.sleep(1000)
/// } // test took 1000.0ms
/// ```
pub fn callback_ns(with callback: fn(Float) -> _, time body: fn() -> a) -> a {
  let #(return, ns) = ffi.elapsed(during: body)

  callback(ns)

  return
}

/// > **Note**: Be aware of side effects when using any of the summary functions.
/// > `body` will be called multiple times and any side effects will be triggered each time.
/// 
/// Shortcut to the [`simple`](./pocket_watch/summary.html#simple) function in the [`summary`](./pocket_watch/summary.html) module.
///
/// Check out that function for details!
pub fn summary_simple(
  label label: String,
  runs n: Int,
  warmup warmup: Int,
  time body: fn() -> a,
) -> a {
  summary.simple(label:, runs: n, warmup:, time: body)
}
