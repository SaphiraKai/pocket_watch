import booklet
import gleam/erlang/process
import gleam/int
import pocket_watch

import gleeunit

import pocket_watch/summary.{Summary}

pub fn main() {
  // let booklet = booklet.new(200)

  // let function_that_gets_faster_over_time = fn() {
  //   function_that_gets_faster_over_time(booklet)
  // }

  // {
  //   use <- summary.callback(
  //     runs: 10_000,
  //     warmup: 100,
  //     with: summary.label("sprint", summary.rates),
  //   )

  //   function_that_gets_faster_over_time()
  // }
  // // pocket_watch [sprint]: warmup: 100/15.15s, total post-warmup: 10000/5.16s 

  let Summary(
    values:,
    times:,
    runs:,
    warmup_runs:,
    warmup:,
    total:,
    min:,
    max:,
    median:,
    mean:,
  ) = summary.collect(runs: 100, warmup: 0, time: yet_another_function)

  gleeunit.main()
}

fn yet_another_function() -> a {
  todo
}

fn function_that_gets_faster_over_time(booklet) {
  process.sleep(int.max(booklet.get(booklet), 0))
  booklet.update(booklet, int.subtract(_, 1))
}

fn function_thats_usually_fast_but_occasionally_really_slow() {
  let n = int.random(1000)

  case n > 950 {
    True -> process.sleep(n / 10)
    False -> process.sleep(n / 100)
  }
}
