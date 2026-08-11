import gleam/io
import gleam/list

import humanise

/// A single step in a sequence of timed steps.
pub type Step(time) {
  Step(label: String, elapsed: time)
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

/// Tracks the previous steps, the current step's label, elapsed time, and callback until resolved to a [`Return`](./step.html#Return) by [`collect`](./step.html#collect).
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
