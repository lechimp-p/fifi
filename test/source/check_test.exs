defmodule Fifi.Source.CheckTest do
  use ExUnit.Case, async: true
  doctest Fifi.Source.Check

  alias Fifi.Source.Check, as: Check

  def init(states, initial_state \\ nil) do
    {:ok, updates} = Agent.start(fn -> states end)
    get_state = fn -> Agent.get_and_update(updates, fn [h | t] -> {h,t} end) end
    {:ok, retreiver} = Agent.start(fn -> [] end)
    on_update = fn v -> Agent.update(retreiver, fn s -> [v | s] end) end
    {:ok, _} = Check.start(1, get_state, on_update, initial_state)
    {updates, retreiver}
  end

  @tag :capture_log
  test "calls on_change on update" do
    {updates, retreiver} = init([1,2])
    Process.sleep(10)
    assert not Process.alive?(updates)
    assert Agent.get(retreiver, &(&1)) == [2]
  end

  @tag :capture_log
  test "does not call on_change when there was no update" do
    {updates, retreiver} = init([1,1])
    Process.sleep(10)
    assert not Process.alive?(updates)
    assert Agent.get(retreiver, &(&1)) == []
  end

  @tag :capture_log
  test "use initial state" do
    {updates, retreiver} = init([1], 0)
    Process.sleep(10)
    assert not Process.alive?(updates)
    assert Agent.get(retreiver, &(&1)) == [1]
  end
end
