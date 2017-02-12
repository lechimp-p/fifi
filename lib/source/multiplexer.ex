defmodule Fifi.Source.Multiplexer do
  @moduledoc """
  This multiplexes one call to a function to multiple other functions.
  """

  @type listener :: (any -> any)

  @doc """
  Start them multiplexer.
  """
  @spec start_link() :: PID
  def start_link() do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Add a function to the multiplexer.
  """
  @spec add(PID, listener) :: reference
  def add(multiplexer, listener) when is_function(listener, 1) do
    ref = make_ref()
    Agent.update(multiplexer, fn map -> Map.put(map, ref, listener) end)
    ref
  end

  @doc """
  Remove a function from the multiplexer.
  """
  @spec remove(PID, reference) :: :ok|:error
  def remove(multiplexer, reference) do
    if Agent.get(multiplexer, &(Map.has_key?(&1, reference))) do
      Agent.update(multiplexer, &(Map.delete(&1, reference)))
      :ok
    else
      :error
    end
  end

  @doc """
  Call the functions in the multiplexer.
  """
  @spec call(PID, any) :: nil
  def call(multiplexer, value) do
    fs = Agent.get(multiplexer, &(Map.to_list(&1)))
    Enum.map(fs, fn {_,f} -> f.(value) end)
    nil
  end
end
