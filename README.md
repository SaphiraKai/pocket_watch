# pocket_watch

[![Package Version](https://img.shields.io/hexpm/v/pocket_watch)](https://hex.pm/packages/pocket_watch)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/pocket_watch/)

`pocket_watch` is a lightweight rapid benchmarking library.

If you have a function or two that are taking longer than expected to run,
you can quickly measure their execution time using this library!

> Well it's fast *most of the time*, but sometimes it gets really slow.

Try one of the [`summary`](./pocket_watch/summary.html) functions, which
collect execution times over multiple runs and give you aggregate stats.
You can even run a function multiple times each time it's called, and simply
return the first value collected without interrupting your normal control flow!

> I figured out which of my big functions is the problem, but there's a lot of
> moving parts inside and I'm not sure which step is slowing me down the most.

Sounds like a job for the [`step`](./pocket_watch/step.html) module! Divide
your big function into multiple steps, and get realtime feedback on how long
each step is taking. Or, cut right to the chase and just find the slowest step.

> Cool. Can I trace the execution time of *every* function called in my
> application throughout its lifecycle, along with memory usage and
> cache-miss rates?

Whoa there buckaroo&ndash; this is a pocket watch, **not a profiler**!

If you need more control, more precision, or a deeper integration into your
runtime, I suggest looking into Erlang or JavaScript-specific profiling tools.

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


Further documentation can be found at <https://hexdocs.pm/pocket_watch>.

## Development

```sh
gleam test  # Run the tests
```
