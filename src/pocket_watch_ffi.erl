-module(pocket_watch_ffi).

-export([elapsed/1, monotonic_now/0]).

elapsed(Fun) ->
    Start = erlang:monotonic_time(),
    Return = Fun(),
    Stop = erlang:monotonic_time(),
    Elapsed = float(erlang:convert_time_unit(Stop - Start, native, nanosecond)),

    {Return, Elapsed}.

monotonic_now() ->
    float(erlang:convert_time_unit(erlang:monotonic_time(), native, nanosecond)).
