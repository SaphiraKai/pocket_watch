import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/time/duration.{type Duration}

import humanise

pub type Stats(value) {
  Stats(
    values: List(value),
    total: Duration,
    min: Duration,
    max: Duration,
    median: Duration,
    mean: Duration,
  )
}

pub fn stats_to_string(stats: Stats(_)) -> String {
  "runs: "
  <> int.to_string(list.length(stats.values))
  <> ", total: "
  <> humanise.duration(stats.total)
  <> ", min: "
  <> humanise.duration(stats.min)
  <> ", max: "
  <> humanise.duration(stats.max)
  <> ", median: "
  <> humanise.duration(stats.median)
  <> ", mean: "
  <> humanise.duration(stats.mean)
}

@external(erlang, "pocket_watch_ffi", "elapsed")
@external(javascript, "pocket_watch_ffi.mjs", "elapsed")
fn elapsed(during fun: fn() -> a) -> #(a, Float)

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
///   use <- pocket_watch.callback("test", print_time)
///
///   process.sleep(1000)
/// } // test took 1.0s
/// ```
pub fn callback(with callback: fn(String) -> Nil, time body: fn() -> a) -> a {
  let callback = fn(elapsed) { callback(humanise.nanoseconds_float(elapsed)) }

  callback_ns(callback, body)
}

/// Log time taken using a provided callback that takes `Float` nanoseconds as argument.
///
/// ## Examples:
/// ```
/// let print_time = fn(label, elapsed) {
///   io.println_error(label <> " took " <> int.to_string(elapsed / 1_000_000) <> "ms")
/// }
///
/// {
///   use <- pocket_watch.callback("test", print_time)
///
///   process.sleep(1000)
/// } // test took 1000ms
/// ```
pub fn callback_ns(with callback: fn(Float) -> _, time body: fn() -> a) -> a {
  let #(return, ns) = elapsed(during: body)

  callback(ns)

  return
}

pub fn collect(runs n: Int, time body: fn() -> a) -> Stats(a) {
  let zero = duration.nanoseconds(0)
  use <- bool.guard(
    when: n < 1,
    return: Stats([], zero, zero, zero, zero, zero),
  )

  let #(values, times) =
    int.range(0, n, [], fn(acc, _) { [elapsed(body), ..acc] }) |> list.unzip
  let times = list.map(times, float.round) |> list.sort(int.compare)

  let assert Ok(min) = list.first(times) |> result.map(duration.nanoseconds)
  let assert Ok(max) = list.last(times) |> result.map(duration.nanoseconds)
  let total = int.sum(times)
  let mean = duration.nanoseconds(total / n)
  let median = case n % 2 {
    0 -> {
      let assert #(_, [a, b, ..]) = list.split(times, n / 2 - 1)
      duration.nanoseconds({ a + b } / 2)
    }
    1 -> {
      let assert #(_, [median, ..]) = list.split(times, n / 2)
      duration.nanoseconds(median)
    }
    _ -> panic as "unreachable"
  }

  Stats(values:, total: duration.nanoseconds(total), min:, max:, median:, mean:)
}

pub fn main() {
  let stats = collect(runs: 100, time: fn() { list.repeat("meow", 1_000_000) })

  io.println_error(stats_to_string(stats))
}
