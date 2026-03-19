# pocket_watch

[![Package Version](https://img.shields.io/hexpm/v/pocket_watch)](https://hex.pm/packages/pocket_watch)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/pocket_watch/)

`pocket_watch` is a lightweight rapid benchmarking library.

If you have a function or two that are taking longer than expected to run,
you can quickly measure their execution time using this library!

> Well it's fast *most of the time*, but sometimes it gets really slow.

Try one of the [`summary`](./pocket_watch/summary.html) functions, which collect execution times over
multiple runs and give you aggregate stats. You can even run a function
multiple times each time it's called, and simply return the first value
collected without interrupting your normal control flow!

> Cool. Can I trace the execution time of *every* function called in my
> application throughout its lifecycle, along with memory usage and
> cache-miss rates?

Whoa there buckaroo&ndash; this is a pocket watch, **not a profiler**!

If you need more control, more precision, or a deeper integration into your runtime, I suggest looking into Erlang&ndash; or JavaScript-specific profiling tools.

```sh
gleam add pocket_watch@2
```

---
## Examples

### Simple:
```gleam
import pocket_watch

pub fn main() {
  use <- pocket_watch.simple("with `use`")

  a_long()
  |> long
  |> very_slow
  |> pipeline
}
// pocket_watch [with `use`]: took 42.0s
```

### Without `use`:
```gleam
import pocket_watch

pub fn main() {
  let fun = fn() { a_slow_function("with", "arguments") }

  pocket_watch.simple("without `use`", fun)
}
// pocket_watch [without `use`]: took 800ms
```

### With a custom callback:
```gleam
import simplifile
import pocket_watch

fn log_time(label, elapsed) {
  simplifile.append(
    to: "./log.txt",
    contents: label <> ": took " <> elapsed <> "\n",
  )
}

pub fn main() {
  use <- pocket_watch.callback(log_time("logged function", _))

  another_very()
  slow_block_of_code()
}
// in ./log.txt:
// logged function: took 6.9m
```

### Run a function multiple times and aggregate the results:
```gleam
import pocket_watch

pub fn main() {
  use <- pocket_watch.summary_simple("simple summary", runs: 100, warmup: 0)

  function_thats_usually_fast_but_occasionally_really_slow()
}
// pocket_watch [simple summary]: min: 210.0ns, max: 100.02ms, median: 6.0ms, mean: 12.77ms
//                                warmup: 0/0.0ns, total post-warmup: 100/1.28s
```

### Aggregate with a custom callback:
```gleam
import pocket_watch/summary

pub fn main() {
  use <- summary.callback(
    runs: 10_000,
    warmup: 100,
    with: summary.label("sprint", summary.show_rates),
  )

  function_that_gets_faster_over_time()
}
// pocket_watch [sprint]: warmup: 6.6/s, post-warmup: 13.63/s
```

### Collect a summary to work with directly:
```gleam
import pocket_watch/summary.{Summary}

pub fn main() { 
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
