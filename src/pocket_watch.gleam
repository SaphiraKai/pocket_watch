import gleam/erlang/process
import gleam/int
import gleam/io

import birl
import humanise

/// Log time taken using a default callback with `io.println`.
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
  let print_time = fn(label, elapsed) {
    io.println("pocket_watch [" <> label <> "]: took " <> elapsed)
  }

  callback(label, print_time, body)
}

/// Log time taken using a provided callback.
///
/// ## Examples:
/// ```
/// let print_time = fn(label, elapsed) { io.println(label <> " took " <> elapsed) }
///
/// {
///   use <- pocket_watch.callback("test", print_time)
///
///   process.sleep(1000)
/// } // test took 1.0s
/// ```
pub fn callback(
  label label: String,
  with callback: fn(String, String) -> Nil,
  time body: fn() -> a,
) -> a {
  let callback = fn(label, elapsed) {
    callback(label, humanise.microseconds_int(elapsed))
  }

  callback_us(label, callback, body)
}

/// Log time taken using a provided callback that takes `Int` microseconds as argument.
///
/// ## Examples:
/// ```
/// let print_time = fn(label, elapsed) {
///   io.println(label <> " took " <> int.to_string(elapsed / 1_000) <> "ms")
/// }
///
/// {
///   use <- pocket_watch.callback("test", print_time)
///
///   process.sleep(1000)
/// } // test took 1000ms
/// ```
pub fn callback_us(
  label label: String,
  with callback: fn(String, Int) -> Nil,
  time body: fn() -> a,
) -> a {
  let start = birl.monotonic_now()
  let res = body()
  let elapsed = birl.monotonic_now() - start

  callback(label, elapsed)

  res
}
