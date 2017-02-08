-module(lager_pretty).

-define(LEVELS,
        [debug, info, notice, warning, error,
         critical, alert, emergency, none]).

-export([parse_transform/2]).

parse_transform(Forms, _Options) ->
    walk_forms(Forms).

walk_forms(Forms) ->
    walk_forms(Forms, []).

walk_forms([], Acc) ->
    lists:reverse(Acc);
walk_forms([{attribute, _, module, Module}=H|T], Acc) ->
    put(module, Module),
    walk_forms(T, [H|Acc]);
walk_forms([{function, Line, Name, Arity, Clauses}|T], Acc) ->
    walk_forms(T, [{function, Line, Name, Arity, walk_clauses(Clauses)}|Acc]);
walk_forms([Form|Forms], Acc) ->
    walk_forms(Forms, [Form|Acc]).

walk_clauses(Clauses) ->
    walk_clauses(Clauses, []).

walk_clauses([], Acc) ->
    lists:reverse(Acc);
walk_clauses([{clause, Line, Arguments, Guards, Body}|T], Acc) ->
    walk_clauses(T, [{clause, Line, Arguments, Guards, walk_body(Body)}|Acc]).

walk_body(Body) ->
    walk_body(Body, []).

walk_body([], Acc) ->
    lists:reverse(Acc);
walk_body([Stmt|Body], Acc) ->
    walk_body(Body, [transform_statement(Stmt)|Acc]).

transform_statement({call, Line,
                     {remote, _Line1,
                      {atom, _Line2, lager},
                      {atom, _Line3, Function}}=F,
                     Arguments}) ->
    NewArguments = case lists:member(Function, ?LEVELS) of
                       true  -> transform_arguments(Arguments);
                       false -> Arguments
                   end,
    {call, Line, F, NewArguments};
transform_statement(Stmt) when is_tuple(Stmt) ->
    list_to_tuple(transform_statement(tuple_to_list(Stmt)));
transform_statement(Stmt) when is_list(Stmt) ->
    lists:map(fun transform_statement/1, Stmt);
transform_statement(Stmt) ->
    Stmt.

transform_arguments(Arguments) ->
    transform_arguments(Arguments, []).

transform_arguments([], Acc) ->
    lists:reverse(Acc);
transform_arguments([H|T], Acc) when element(1, H) == cons ->
    transform_arguments(T, [transform_list(H)|Acc]);
transform_arguments([H|T], Acc) ->
    transform_arguments(T, [H|Acc]).

transform_list({nil, _Line}=Nil) ->
    Nil;
transform_list({cons, Line, Value, L}) ->
    {cons, Line, do_transform(Value, Line), transform_list(L)}.

do_transform({call, _Line,
              {remote, _Line, {atom, _Line, lager},
               {atom, _Line, pr}}, _Args}=Call, _Line) ->
    Call;
do_transform(Value, Line) ->
    {call, Line,
     {remote, Line, {atom, Line, lager}, {atom, Line, pr}},
     [Value, {atom, Line, get(module)}]}.
