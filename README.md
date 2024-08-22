# pocket_watch

[![Package Version](https://img.shields.io/hexpm/v/pocket_watch)](https://hex.pm/packages/pocket_watch)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/pocket_watch/)

```sh
gleam add pocket_watch@1
```
```gleam
import gleam/io
import pocket_watch

pub fn main() {
  {
    use <- pocket_watch.simple("test 1")

    a_long()
    |> long
    |> very
    |> slow
    |> pipeline
  } // pocket_watch [test 1]: took 42.0s

  {
    let print_time = fn(label, elapsed) { io.println(label <> " took a whole " <> elapsed <> "!") }
    use <- pocket_watch.callback("test 2", print_time)

    another_very()
    slow_block_of_code()
  } // test 2 took a whole 6.9m!

  let fun = fn() { a_slow_function("with", "arguments") }
  
  pocket_watch.simple("test 3", fun) // pocket_watch [test 3]: took 800ms
}
```

Further documentation can be found at <https://hexdocs.pm/pocket_watch>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
