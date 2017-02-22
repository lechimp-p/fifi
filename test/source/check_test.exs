defmodule Fifi.Source.CheckTest do
  use ExUnit.Case, async: true
  doctest Fifi.Source.Check

  alias Fifi.Source.Check, as: Check

  setup do
    {:ok, state} = Agent.start_link(fn -> :initial end)
    get_state = fn -> Agent.get(state, &(&1)) end
    set_state = fn s -> Agent.update(state, fn _ -> s end) end

    {:ok, retreiver} = Agent.start_link(fn -> [] end)
    on_change = fn h -> Agent.update(retreiver, fn t -> [h | t] end) end
    get_retrieved = fn -> Agent.get(retreiver, &(&1)) end

    {:ok, _} = Check.start_link(1, get_state, on_change, :initial)

    {:ok, set_state: set_state, get_retrieved: get_retrieved}
  end

  test "calls on_change on update", %{set_state: set_state, get_retrieved: get_retrieved} do
    set_state.(1)
    Process.sleep(10)
    assert get_retrieved.() == [1]
  end

  test "does not call on_change when there was no update", %{set_state: set_state, get_retrieved: get_retrieved} do
    set_state.(1)
    set_state.(1)
    set_state.(1)
    Process.sleep(10)
    assert get_retrieved.() == [1]
  end

  test "use initial value", %{set_state: set_state, get_retrieved: get_retrieved} do
    set_state.(:initial)
    Process.sleep(10)
    assert get_retrieved.() == []
  end
end
