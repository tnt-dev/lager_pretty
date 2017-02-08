lager_pretty
============

Simple parse transform that makes Lager's logs a bit more pretty
wrapping all arguments of logging functions with `lager:pr/2`.

Usage
-----

Just add `{parse_transform, lager_pretty}` to your .erl files or rebar config
BEFORE `{parse_transform, lager}`.

Example
-------

Without `lager_pretty`:

```erlang
-module(t1).
-compile(export_all).
-compile({parse_transform, lager_transform}).

-record(rec, {x, y, z}).

log() ->
    R = #rec{x=10, y=20, z=30},
    lager:info("~p", [R]).
```

```
1> t1:log().
ok
17:04:32.672 [info] {rec,10,20,30}
```

With:

```erlang
-module(t2).
-compile(export_all).
-compile({parse_transform, lager_pretty}).
-compile({parse_transform, lager_transform}).

-record(rec, {x, y, z}).

log() ->
    R = #rec{x=10, y=20, z=30},
    lager:info("~p", [R]).
```

```
1> t2:log().
ok
17:06:44.484 [info] #rec{x=10,y=20,z=30}
```
