defmodule EvaluateTest do
  use ExUnit.Case
  doctest Evaluate

  test "print" do
    assert Evaluate.print({:num, 2}) == '2'
    assert Evaluate.print({:var, 'b'}) == 'b'
    assert Evaluate.print({:add, {:num, 2}, {:var, :b}}) == '(2+b)'
    assert Evaluate.print({:sub, {:num, 2}, {:var, :b}}) == '(2-b)'
    assert Evaluate.print({:mul, {:num, 3}, {:num, 5}}) == '(3*5)'
    assert Evaluate.print({:div, {:num, 3}, {:num, 5}}) == '(3/5)'
    assert Evaluate.print({:add, {:num, 2}, {:mul, {:num, 3}, {:num, 4}}}) == '(2+(3*4))'
  end

  test "eval" do
    assert Evaluate.eval([], {:add, {:num, 2}, {:num, 3}}) == 5
    assert Evaluate.eval([], {:sub, {:num, 6}, {:num, 3}}) == 3
    assert Evaluate.eval([], {:mul, {:num, 2}, {:num, 3}}) == 6
    assert Evaluate.eval([], {:div, {:num, 2}, {:num, 3}}) == 2/3
  end
  
  test "eval with lookup" do
    env = [{:a, 3}, {:b, 2}]
    assert Evaluate.eval(env, {:add, {:var, :a}, {:var, :b}}) == 5
    assert Evaluate.eval(env, {:sub, {:var, :a}, {:var, :b}}) == 1
    assert Evaluate.eval(env, {:mul, {:var, :a}, {:var, :b}}) == 6
    assert Evaluate.eval(env, {:div, {:var, :a}, {:var, :b}}) == 3/2
  end

  test "parse" do
    assert Evaluate.parse('2') == {{:num, 2}, []}
    assert Evaluate.parse('-2') == {{:num, -2}, []}
    assert Evaluate.parse('(2+(3*4))') == {{:add, {:num, 2}, {:mul, {:num, 3}, {:num, 4}}}, []}
    assert Evaluate.parse('(22+(3*b))') == {{:add, {:num, 22}, {:mul, {:num, 3}, {:var, 'b'}}}, []}
    assert Evaluate.parse('(22-(33/b))') == {{:sub, {:num, 22}, {:div, {:num, 33}, {:var, 'b'}}}, []}
    assert Evaluate.parse('(1+(22-(33/b)))') == {{:add, {:num, 1}, {:sub, {:num, 22}, {:div, {:num, 33}, {:var, 'b'}}}}, []}
  end
  test "parser" do
    assert Evaluate.parser({{:num, 2}, []}) == {:num, 2}
  end
  test "simplify" do
    assert Evaluate.simplify({:add, {:num, 0}, {:var, 'b'}}) == {:var,'b'}
    assert Evaluate.simplify({:mul, {:num, 1}, {:var, 'b'}}) == {:var,'b'}
    assert Evaluate.simplify({:sub, {:var, 'b'}, {:num, 0}}) == {:var,'b'}
    assert Evaluate.simplify({:div, {:var, 'b'}, {:num, 1}}) == {:var,'b'}
    assert Evaluate.simplify({:mul, {:num, 0}, {:var, 'b'}}) == {:num, 0}
    assert Evaluate.simplify({:add, {:mul, {:num, 1}, {:var, 'b'}}, {:mul, {:mul, {:var, 'b'}, {:num, 1}}, {:num, 0}}}) == {:var, 'b'}
  end
  assert Evaluate.parse('((0+b)+((2*0)+(23/1)))')
          |> Evaluate.parser()
          |> Evaluate.simplify()
          |> Evaluate.print() == '(b+23)'
end
