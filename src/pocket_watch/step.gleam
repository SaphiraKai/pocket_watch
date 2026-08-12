//// This module is intended for cases where you have multiple steps in a
//// time-consuming operation, and you'd like to figure out which step(s) are your bottleneck.
////
//// ## Examples:
//// ### Log each step's timing as it runs:
//// ```gleam
//// let step.Return(wabble, _) =
////   step.collect({
////     use <- step.simple("loading wibble") // using `simple` callback for logging
////     let wibble = load_wibble()
////     // pocket_watch [loading wibble]: took 80ms
////
////     use <- step.next("parsing wibble")
////     let wobble = wobble.parse_wibble(wibble)
////     // pocket_watch [parsing wibble]: took 150ms
////
////     use <- step.next("wobble -> wabble conversion")
////     let wabble = wobble.to_wabble(wobble)
////     // pocket_watch [wobble -> wabble conversion]: took 500ms
////
////     step.finish(wabble)
////   })
////
//// // do something with the returned wabble
//// ```
////
//// ### Find the slowest step as a percentage of the total time, without logging:
//// ```gleam
//// let step.Return(_wabble, steps:) =
////   step.collect({
////     use <- step.next("loading wibble") // no callback has been provided, so no logging will be done
////     let wibble = load_wibble()
////
////     use <- step.next("parsing wibble")
////     let wobble = wobble.parse_wibble(wibble)
////
////     use <- step.next("wobble -> wabble conversion")
////     let wabble = wobble.to_wabble(wobble)
////
////     step.finish(wabble)
////   })
////
//// steps |> list.sort(step.compare) |> step.percent(0) |> list.last |> echo
//// // Ok(Step("wobble -> wabble conversion", "68%"))
//// ```
////
//// ### Find the total time of multiple steps:
//// ```gleam
//// let step.Return(_wabble, steps:) =
////   step.collect({
////     use <- step.next("loading wibble")
////     let wibble = load_wibble()
//// 
////     use <- step.next("parsing wibble")
////     let wobble = wobble.parse_wibble(wibble)
////
////     use <- step.next("wobble -> wabble conversion")
////     let wabble = wobble.to_wabble(wobble)
////
////     step.finish(wabble)
////   })
//// 
//// steps |> step.total(", ") |> step.humanise |> echo
//// // Step("[loading wibble], [parsing wibble], [wobble -> wabble conversion]", "730ms")
//// ```
////
//// ### Specify multiple callbacks:
//// ```gleam
//// let print_nanoseconds = fn(label, elapsed) {
////   io.println_error(
////     label <> " took " <> float.to_string(elapsed) <> " nanoseconds",
////   )
//// }
//// 
//// let print_if_slow = fn(label, elapsed) {
////   case elapsed >. 250.0e6 {
////     False -> Nil
////     True ->
////       io.println_error(
////         "warning: "
////         <> label
////         <> " took more than 250ms ("
////         <> humanise.nanoseconds_float(elapsed)
////         <> ")",
////       )
////   }
//// }
////
//// step.collect({
////   use <- step.simple("loading wibble")
////   let wibble = load_wibble()
////   // pocket_watch [loading wibble]: took 80ms
//// 
////   use <- step.callback_ns("parsing wibble", print_nanoseconds)
////   let wobble = parse_wibble(wibble)
////   // parsing wibble took 150000000.0 nanoseconds
////
////   use <- step.callback_ns("wobble -> wabble conversion", print_if_slow)
////   let wabble = wobble_to_wabble(wobble)
////   // warning: wobble -> wabble conversion took more than 250ms (500ms)
////
////   step.finish(wabble)
//// })
//// ```

import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/order.{type Order}
import gleam/string

import humanise

/// A single step in a sequence of timed steps.
pub type Step(time) {
  Step(label: String, elapsed: time)
}

/// Compare step times.
pub fn compare(left: Step(Float), right: Step(Float)) -> Order {
  float.compare(left.elapsed, right.elapsed)
}

/// Convert a step's elapsed time from nanoseconds to a human-readable string.
pub fn humanise(step: Step(Float)) -> Step(String) {
  Step(..step, elapsed: humanise.nanoseconds_float(step.elapsed))
}

/// Find the total time elapsed over multiple steps.
///
/// Labels are combined using the separator; using `", "`:
/// ```gleam
/// ["first", "second", "third"]
/// ```
/// Becomes:
/// ```gleam
/// "[first], [second], [third]"
/// ```
pub fn total(steps: List(Step(Float)), separator: String) -> Step(Float) {
  let #(labels, times) =
    list.map(steps, fn(s) { #(s.label, s.elapsed) }) |> list.unzip

  let label =
    list.map(labels, fn(l) { "[" <> l <> "]" }) |> string.join(separator)
  let elapsed = float.sum(times)

  Step(label:, elapsed:)
}

/// Convert step times to percentages of the total time.
///
/// `precision` is clamped to `0` or greater.
pub fn percent(steps: List(Step(Float)), precision: Int) -> List(Step(String)) {
  let precision = int.max(precision, 0)
  let Step(_, total) = total(steps, "")

  let to_percent = case precision {
    0 -> fn(f) { float.round(f /. total *. 100.0) |> int.to_string <> "%" }
    _ -> fn(f) {
      float.to_precision(f /. total *. 100.0, precision) |> float.to_string
      <> "%"
    }
  }

  list.map(steps, fn(s) { Step(..s, elapsed: to_percent(s.elapsed)) })
}

type State {
  State(
    label: String,
    timestamp: Float,
    steps: List(Step(Float)),
    callback: fn(String, Float) -> Nil,
  )
}

fn new_state() -> State {
  State(label: "", timestamp: 0.0, steps: [], callback: fn(_, _) { Nil })
}

/// Collected results from calling [`collect`](./step.html#collect).
///
/// - `return`: The return value passed to [`finish`](./step.html#finish)
/// - `steps`: The list of tracked steps and their elapsed time in nanoseconds
pub type Return(return) {
  Return(return: return, steps: List(Step(Float)))
}

/// Tracks the previous steps, and the current step's label, elapsed time, and callback, until resolved to a [`Return`](./step.html#Return) by [`collect`](./step.html#collect).
pub opaque type StepTracker(return) {
  StepTracker(resolve: fn(State) -> Return(return))
}

@external(erlang, "pocket_watch_ffi", "monotonic_now")
@external(javascript, "../pocket_watch_ffi.mjs", "monotonic_now")
fn monotonic_now() -> Float

/// Time a new step using a default callback that uses `io.println_error`.
///
/// ## Examples:
/// ```gleam
/// step.collect({
///   use <- step.simple("test")
///
///   process.sleep(1000)
///   // pocket_watch [test]: took 1.0s
/// 
///   use <- step.next("another test")
///
///   process.sleep(2000)
///   // pocket_watch [another test]: took 2.0s
/// 
///   step.finish(Nil)
/// })
/// ```
pub fn simple(
  label label: String,
  continue continue: fn() -> StepTracker(return),
) -> StepTracker(return) {
  use <- next(label:)
  use state <- StepTracker

  let callback = fn(label, elapsed) {
    io.println_error(
      "pocket_watch ["
      <> label
      <> "]: took "
      <> humanise.nanoseconds_float(elapsed),
    )
  }
  continue().resolve(State(..state, callback:))
}

/// Time a new step using a provided callback.
///
/// ## Examples:
/// ```gleam
/// let print_time = fn(label, elapsed) {
///   io.println_error(label <> " took " <> elapsed)
/// }
/// 
/// step.collect({
///   use <- step.callback("test", with: print_time)
///
///   process.sleep(1000)
///   // test took 1.0s
/// 
///   use <- step.next("another test")
///
///   process.sleep(2000)
///   // another test took 2.0s
/// 
///   step.finish(Nil)
/// })
/// ```
pub fn callback(
  label label: String,
  with callback: fn(String, String) -> Nil,
  continue continue: fn() -> StepTracker(return),
) -> StepTracker(return) {
  use <- next(label:)
  use state <- StepTracker

  let callback = fn(label, elapsed) {
    callback(label, humanise.nanoseconds_float(elapsed))
  }

  continue().resolve(State(..state, callback:))
}

/// Time a new step using a provided callback that takes `Float` nanoseconds as argument.
///
/// ## Examples:
/// ```gleam
/// let print_time = fn(label, elapsed) {
///   io.println_error(label <> " took " <> float.to_string(elapsed /. 1_000_000.0) <> "ms")
/// }
/// 
/// step.collect({
///   use <- step.callback_ns("test", with: print_time)
///
///   process.sleep(1000)
///   // test took 1000.0ms
/// 
///   use <- step.next("another test")
///
///   process.sleep(2000)
///   // another test took 2000.0ms
/// 
///   step.finish(Nil)
/// })
/// ```
pub fn callback_ns(
  label label: String,
  with callback: fn(String, Float) -> Nil,
  continue continue: fn() -> StepTracker(return),
) -> StepTracker(return) {
  use <- next(label:)
  use state <- StepTracker

  continue().resolve(State(..state, callback:))
}

/// Time a new step using the previous callback.
///
/// Can also be used to track step timing without logging anything.
/// ## Examples:
/// ```gleam
/// let step.Return(Nil, steps:) =
///   step.collect({
///     use <- step.next("test")
///
///     process.sleep(1000)
///     // nothing is logged here
///
///     use <- step.next("another test")
///
///     process.sleep(2000)
///     // or here
///
///     step.finish(Nil)
///   })
///
/// list.each(steps, fn(s) {
///   io.println(s.label <> ": " <> humanise.nanoseconds_float(s.elapsed))
/// })
/// // test: 1.0s
/// // another test: 2.0s
/// ```
pub fn next(
  label new_label: String,
  continue continue: fn() -> StepTracker(return),
) -> StepTracker(return) {
  let now = monotonic_now()

  use State(label:, timestamp:, steps:, callback:) <- StepTracker

  let elapsed = now -. timestamp
  callback(label, elapsed)
  let correction = monotonic_now() -. now

  let state =
    State(
      label: new_label,
      timestamp: now +. correction,
      steps: [Step(label:, elapsed:), ..steps],
      callback:,
    )

  continue().resolve(state)
}

/// Finish a sequence of steps and return a value that can be collected.
///
/// ## Examples:
/// ```gleam
/// step.collect({
///   use <- step.next("a step")
/// 
///   step.finish("a value")
/// }).return
/// |> io.println // a value
/// ```
pub fn finish(return return: return) -> StepTracker(return) {
  use State(label:, timestamp:, steps:, callback:) <- StepTracker

  let now = monotonic_now()
  let elapsed = now -. timestamp
  callback(label, elapsed)

  Return(return:, steps: [Step(label:, elapsed:), ..steps])
}

/// Collect a sequence of steps into a [`Return`](./step.html#Return).
///
/// ## Examples:
/// ```gleam
/// let Return(return: Nil, steps:) = step.collect({
///   use <- step.next("step")
/// 
///   step.finish(Nil)
/// })
/// ```
pub fn collect(tracker: StepTracker(return)) -> Return(return) {
  let Return(return:, steps:) = tracker.resolve(new_state())

  Return(return:, steps: list.reverse(steps) |> list.drop(1))
}
