defmodule Fifi.Source.Check do
  @moduledoc """
  Frequently performs a check on some state and notifies on change.
  """
  use GenServer

  def start_link(frequency, get_state, on_change) do
    GenServer.start_link(__MODULE__, {frequency, get_state, on_change})
  end

  def start(frequency, get_state, on_change) do
    GenServer.start(__MODULE__, {frequency, get_state, on_change})
  end

  def init({frequency, get_state, on_change}) do
    schedule_check(frequency)
    current_state = get_state.()
    {:ok, %{frequency: frequency,
            get_state: get_state,
            current_state: current_state,
            on_change: on_change}}
  end

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
