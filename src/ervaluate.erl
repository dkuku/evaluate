-module(ervaluate).
-export([print/1, eval/2, compile/1, run/3, parse/1, simplify/1]).

% to use from iex
% c "src/ervaluate.erl"
% :ervaluate.parse('(2*3)')

-type expr() :: {var, atom()}
| {num, integer()}
| {mul, expr(), expr()}
| {add, expr(), expr()}.

-type env() :: [{atom(), integer()}].

-type instr() :: {'push', integer()}
| {'fetch', atom()}
| {'add2'}
| {'mul2'}.

-type program() :: [instr()].

-type stack() :: [integer()].


-spec print(expr()) -> string().
print({num, N}) ->
    integer_to_list(N);

print({var, A}) ->
    atom_to_list(A);

print({add, E1, E2}) ->
    "("++ print(E1) ++ "+" ++ print(E2) ++")";

print({mul, E1, E2}) ->
    "("++ print(E1) ++ "*" ++ print(E2) ++")".

-spec eval(env(), expr()) -> integer().
eval(Env, {var, A}) ->
    lookup(A, Env);

eval(_Env, {num, N}) ->
    N;

eval(Env, {add, E1, E2}) ->
    eval(Env, E1) + eval(Env, E2);

eval(Env, {mul, E1, E2}) ->
    eval(Env, E1) * eval(Env, E2).

-spec lookup(atom(), env()) -> integer().
lookup(A, [{A, V}|_]) ->
    V;

lookup(A, [{_, _}|Rest]) ->
    lookup(A, Rest).

-spec compile(expr()) -> program().
compile({num, N}) ->
    [{push, N}];

compile({var, A}) ->
    [{fetch, A}];

compile({add,E1,E2}) ->
    compile(E1) ++ compile(E2) ++ [{add2}];

compile({mul,E1,E2}) ->
    compile(E1) ++ compile(E2) ++ [{mul2}].

-spec run(program(), env(), stack()) -> integer().
run([{push, N} | Continue], Env, Stack) ->
    run(Continue, Env, [N | Stack]);

run([{fetch, A} | Continue], Env, Stack) ->
    run(Continue, Env, [lookup(A, Env)| Stack]);

run([{add2} | Continue], Env, [N1,N2|Stack]) ->
    run(Continue, Env, [(N1 + N2) | Stack]);

run([{mul2} | Continue], Env, [N1,N2|Stack]) ->
    run(Continue, Env, [(N1 * N2) | Stack]);
run([], env, [N]) ->
N.

-spec parse(string()) -> {expr(), string()}.
parse([Ch|Rest]) when $a =< Ch andalso Ch =< $z ->
            {Succeeds, Remainder} = get_while(fun is_alpha/1, Rest),
            {{var, list_to_atom([Ch|Succeeds])}, Remainder};

parse([Ch|Rest]) when $0 =< Ch andalso Ch =< $9 ->
            {Succeeds, Remainder} = get_while(fun is_numeric/1, Rest),
            {{num, list_to_integer([Ch|Succeeds])}, Remainder};

parse([$(|Rest]) ->
    {E1, Rest1} = parse(Rest),
    [Op|Rest2] = Rest1,
    {E2, Rest3} = parse(Rest2),
    [$)|RestFinal] = Rest3,
    {case Op of
         $+ -> {add, E1, E2};
         $* -> {mul, E1, E2}
    end,
    RestFinal}.

-spec get_while(fun((T) -> boolean()), [T]) -> {[T], [T]}.
get_while(P, [Ch|Rest]) ->
    case P(Ch) of
        true ->
            {Succeeds, Remainder} = get_while(P, Rest),
            {[Ch, Succeeds], Remainder};
        false ->
            {[], [Ch|Rest]}
    end;

get_while(_P, []) ->
    {[],[]}.

is_alpha(Ch) -> $a =< Ch andalso Ch =< $z.
is_numeric(Ch) -> $0 =< Ch andalso Ch =< $9.

add({add, E, {num, 0}}) -> 
    E;
add({add, {num, 0}, E}) -> 
    E;
add({add, {num, X}, {num, Y}}) -> 
    {num, X + Y};
add(E) -> 
    E.
mul({mul, {num, 0}, _}) -> 
   {num,0};
mul({mul, _, {num, 0}}) -> 
   {num, 0};
mul({mul, {num, 1}, E}) -> 
   E;
mul({mul, E, {num, 1}}) -> 
   E;
mul({mul, {num, X}, {num, Y}}) -> 
    {num,X * Y};
mul(E) -> 
   E.

compose([])->
    fun (E)-> E end;
compose([Rule|Rules])->
    fun (E) -> (compose(Rules))(Rule(E)) end.

rules() ->
    [fun add/1, fun mul/1].
simp(F, {add, E1,E2})->
    F({add, simp(F, E1), simp(F, E2)});
simp(F, {mul, E1,E2})->
    F({mul, simp(F, E1), simp(F, E2)});
simp(_, E) -> E.
simplify(E) ->
    simp(compose(rules()),E).
