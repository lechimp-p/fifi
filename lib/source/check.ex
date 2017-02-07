defmodule Fifi.Source.Check do
  @moduledoc """
  Frequently performs a check on some state and notifies on change.
  """
  use GenServer

  @type get_state :: (() -> any)
  @type on_change :: (any -> ())

  @doc """
  Start the checker with a frequency (in ms), a state getting function and
  a function saying what to do when the state changes.
  """
  @spec start_link(pos_integer, get_state, on_change) :: GenServer.on_start
  def start_link(frequency, get_state, on_change)
    when (frequency > 0)
    do
      GenServer.start_link(__MODULE__, {frequency, get_state, on_change})
    end

  @doc """
  Start the checker with a frequency (in ms), a state getting function and
  a function saying what to do when the state changes.
  """
  @spec start_link(pos_integer, get_state, on_change) :: GenServer.on_start
  def start(frequency, get_state, on_change)
    when (frequency > 0)
    do
      GenServer.start(__MODULE__, {frequency, get_state, on_change})
    end

  @doc "from GenServer"
  def init({frequency, get_state, on_change}) do
    schedule_check(frequency)
    current_state = get_state.()
    {:ok, %{frequency: frequency,
            get_state: get_state,
            current_state: current_state,
            on_change: on_change}}
  end

  @doc "from GenServer"
  def handle_info(:check, state) do
    new_state = check(state)
    schedule_check(state.frequency)
    {:noreply, %{state | current_state: new_state}}
  end

  defp schedule_check(frequency) do
    Process.send_after(self(), :check, frequency)
  end

  defp check(state) do
    new_state = state.get_state.()
    if state.current_state != new_state do
      state.on_change.(new_state)
    end
    new_state
  end
end
