defmodule Evaluate do
  import Guards

  @type expr() :: {:num, integer()}
  | {:var, atom()}
  | {:add, expr(), expr()}
  | {:mul, expr(), expr()}

  @type env() :: [{atom(), integer()}]

  @type instr() :: {:push, integer()}
  | {:fetch, atom()}
  | {:add2}
  | {:mul2}

  @type program() :: [instr()]

  @type stack() :: [integer()]

  @spec print(expr()) :: charlist()
  def print({:num, n}), do: Integer.to_charlist(n)
  def print({:var, v}), do: v
  def print({:add, e1, e2}), do: '(#{print(e1)}+#{print(e2)})'
  def print({:sub, e1, e2}), do: '(#{print(e1)}-#{print(e2)})'
  def print({:div, e1, e2}), do: '(#{print(e1)}/#{print(e2)})'
  def print({:mul, e1, e2}), do: '(#{print(e1)}*#{print(e2)})'

  @spec eval(env(), expr()) :: integer()
  def eval(_env, {:num, n}), do: n
  def eval(env, {:var, v}), do: lookup(v, env)
  def eval(env, {:add, e1, e2}), do: eval(env, e1) + eval(env, e2)
  def eval(env, {:sub, e1, e2}), do: eval(env, e1) - eval(env, e2)
  def eval(env, {:mul, e1, e2}), do: eval(env, e1) * eval(env, e2)
  def eval(env, {:div, e1, e2}), do: eval(env, e1) / eval(env, e2)

  @spec lookup(atom(), env()) :: integer()
  def lookup(a, [{a, v}| _ ]), do: v
  def lookup(v, [ _ | rest ]), do: lookup(v, rest)

  @spec run(program(), env(), stack()) :: integer()
  def run([], _env, [n]), do: n
  def run([{:push, n} | rest], env, stack), do: run(rest, env, [n | stack])
  def run([{:fetch, a} | rest], env, stack), do: run(rest, env, [lookup(a, env) | stack])
  def run([{:add2} | rest], env, [n1, n2 | stack]), do: run(rest, env, [n1 + n2 | stack])
  def run([{:mul2} | rest], env, [n1, n2 | stack]), do: run(rest, env, [n1 * n2 | stack])
  def run([{:div2} | rest], env, [n1, n2 | stack]), do: run(rest, env, [n1 / n2 | stack])
  def run([{:sub2} | rest], env, [n1, n2 | stack]), do: run(rest, env, [n1 - n2 | stack])

  @spec compile(expr()) :: program()
  def compile({:num, n}), do: [{:push, n}]
  def compile({:var, a}), do: [{:fetch, a}]
  def compile({:add, e1, e2}), do: compile(e1) ++ compile(e2) ++ [{:add2}]
  def compile({:mul, e1, e2}), do: compile(e1) ++ compile(e2) ++ [{:mul2}]

  @spec parse(charlist()) :: {expr(), charlist()}
  def parse([?( | rest]) do
    {e1, rest1} = parse(rest)
    [op | rest2 ] = rest1
    {e2, rest3} = parse(rest2)
    [?) | rest_final] = rest3
    {case op do
      ?+ -> {:add, e1, e2}
      ?* -> {:mul, e1, e2}
      ?- -> {:sub, e1, e2}
      ?/ -> {:div, e1, e2}
    end, rest_final}
  end
  def parse([ch | rest]) when is_digit(ch) or ch == ?- do
      {succeeds, remainder} = get_while(&Evaluate.is_num/1, rest)
    {{:num, [ch|succeeds] |> List.to_integer()}, remainder}
  end
  def parse([ch | rest]) when ?a <= ch and ?z >= ch do
    {succeeds, remainder} = get_while(&Evaluate.is_alpha/1, rest)
    {{:var, [ch | succeeds]}, remainder}
  end
  def parser({e, []}), do: e

  def is_alpha(ch) when ?a <= ch and ?z >= ch, do: true
  def is_alpha(_), do: false
  def is_num(ch) when is_digit(ch), do: true
  def is_num(_), do: false


  @spec get_while(fun(t :: boolean()), charlist()) :: {charlist(),charlist()}
  def get_while(p, [ch | rest]) do
    case p.(ch) do
      true -> 
        {succeeds, remainder} = get_while(p, rest)
        {[ch|succeeds], remainder}
      false ->
        {'', [ch|rest]}
    end
  end
  def get_while(_p, ''), do: {'', ''}

  def sub_zero({:sub, expr, {:num, 0}}), do: expr
  def sub_zero(expr), do: expr

  def add_zero({:add, {:num, 0}, expr}), do: expr
  def add_zero({:add, expr, {:num, 0}}), do: expr
  def add_zero(expr), do: expr

  def div_one({:div, expr, {:num, 1}}), do: expr
  def div_one(expr), do: expr

  def mul_one({:mul, expr, {:num, 1}}), do: expr
  def mul_one({:mul, {:num, 1}, expr}), do: expr
  def mul_one(expr), do: expr

  def mul_zero({:mul, {:num, 0}, _expr}), do: {:num, 0}
  def mul_zero({:mul, _expr, {:num, 0}}), do: {:num, 0}
  def mul_zero(expr), do: expr

  def compose([]), do: fn (e) -> e end
  def compose([rule|rules]), do: fn (e) -> (compose(rules)).(rule.(e))  end
  def rules(), do: [&add_zero/1, &mul_one/1, &mul_zero/1, &sub_zero/1, &div_one/1]

  def simp(f, {ex, e1, e2}) when ex in [:add, :mul, :div, :sub], do: f.({ex, simp(f, e1), simp(f, e2)})
  def simp(_f, e), do: e
  def simplify(e), do: rules() |> compose() |> simp(e)
end
