@external(erlang, "pocket_watch_ffi", "elapsed")
@external(javascript, "pocket_watch_ffi.mjs", "elapsed")
pub fn elapsed(during fun: fn() -> a) -> #(a, Float)
