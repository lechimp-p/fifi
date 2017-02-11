defmodule Fifi.Source.Manager do
  @moduledoc """
  Entry point to the sources subsystem.
  """
  use GenServer
  alias Fifi.Source.Registry, as: Registry 

  @doc """
  List all sources manager by the manager.
  """
  @spec list(PID) :: [String.t] 
  def list(manager) do
    GenServer.call(manager, {:list})
  end

  @doc """
  Start a manager.
  """
  @spec start_link([Fifi.Source.Source]) :: PID
  def start_link(sources) do
    GenServer.start_link(__MODULE__, {sources}, [])
  end

  ## Server Callbacks

  ## sets the server up. second arg is state.
  def init({sources}) do
    {:ok, registry} = Registry.start_link()
    Enum.map(sources, fn {name, s} -> Registry.add(registry, name, s) end)
    {:ok, %{registry: registry}}
  end

  ## call is for sync callbacks.
  def handle_call({:list}, _from, state) do
    {:reply, Registry.list(state.registry), state}
  end

  ## cast is for async callbacks, where clients don't care if msg really was
  ## passed.
  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  ## info is for all other messages.
  def handle_info(_msg, state) do
    {:noreply, state}
  end

end
