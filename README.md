# pocket_watch

[![Package Version](https://img.shields.io/hexpm/v/pocket_watch)](https://hex.pm/packages/pocket_watch)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/pocket_watch/)

```sh
gleam add pocket_watch@2
```
```gleam
import gleam/io

import pocket_watch
import pocket_watch/summary

pub fn main() {
  //
  // Labelled, at the top of a function:
  //
  {
    use <- pocket_watch.simple("with `use`")

    a_long()
    |> long
    |> very_slow
    |> pipeline
  } // pocket_watch [with `use`]: took 42.0s

  //
  // Without `use`:
  //
  let fun = fn() { a_slow_function("with", "arguments") }
  pocket_watch.simple("without `use`", fun)
  // pocket_watch [without `use`]: took 800ms

  //
  // With a custom callback:
  //
  {
    let print_time = fn(elapsed) {
      io.println("this function took a whole " <> elapsed <> "!")
    }
    use <- pocket_watch.callback(print_time)

    another_very()
    slow_block_of_code()
  } // this function took a whole 6.9m!

  //
  // Run a function multiple times and aggregate the results:
  //
  {
    use <- pocket_watch.summary_simple("simple summary", runs: 100, warmup: 0)

    function_thats_usually_fast_but_occasionally_really_slow()
  }
  // pocket_watch [simple summary]: min: 210.0ns, max: 100.02ms, median: 6.0ms, mean: 12.77ms
  //                                warmup: 0/0.0ns, total post-warmup: 100/1.28s

  //
  // Aggregate with a custom callback:
  //
  {
    use <- summary.callback(
      runs: 10_000,
      warmup: 100,
      with: summary.label("sprint", summary.overall),
    )

    function_that_gets_faster_over_time()
  } // pocket_watch [sprint]: warmup: 100/15.15s, total post-warmup: 10000/5.16s

  //
  // Collect a summary to work with directly:
  //
  let Summary(
    values:, // List of return values from each run
    times:, // List of times from each run
    runs:, // Number of runs
    warmup_runs:, // Number of warmup runs
    warmup:, // Warmup time elapsed
    total:, // Total (post-warmup) time elapsed
    min:, // Fastest run time
    max:, // Slowest run time
    median:, // Median run time
    mean:, // Mean/average run time
  ) = summary.collect(runs: 100, warmup: 0, time: yet_another_function)
}
```

Further documentation can be found at <https://hexdocs.pm/pocket_watch>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
