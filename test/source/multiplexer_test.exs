defmodule Fifi.Source.MultiplexerTest do
  use ExUnit.Case, async: true
  doctest Fifi.Source.Multiplexer

  alias Fifi.Source.Multiplexer, as: Multiplexer 

  setup do
    {:ok, multiplexer} = Multiplexer.start_link()
    {:ok, multiplexer: multiplexer}
  end

  test "does actual multiplexing", %{multiplexer: multiplexer} do
    {:ok, a1} = Agent.start(fn -> nil end)
    Multiplexer.add(multiplexer, fn v -> Agent.update(a1, fn _ -> v end) end)
    {:ok, a2} = Agent.start(fn -> nil end)
    Multiplexer.add(multiplexer, fn v -> Agent.update(a2, fn _ -> v end) end)
    Multiplexer.call(multiplexer, "Hello World!")
    assert Agent.get(a1, &(&1)) == "Hello World!"
    assert Agent.get(a2, &(&1)) == "Hello World!"
  end
end
