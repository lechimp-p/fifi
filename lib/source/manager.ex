defmodule Fifi.Source.Manager do
  @moduledoc """
  Entry point to the sources subsystem.
  """
  use GenServer
  alias Fifi.Source.Registry, as: Registry 
  alias Fifi.Source.Source, as: Source 

  @doc """
  List all sources manager by the manager.
  """
  @spec list(PID) :: [String.t] 
  def list(manager) do
    GenServer.call(manager, {:list})
  end

  @doc """
  Add a source to the manager.
  """
  @spec add(PID, String.t, Source) :: :ok|:error
  def add(manager, name, source) do
    GenServer.call(manager, {:add, name, source})
  end

  @doc """
  Remove a source from the manager.
  """
  @spec remove(PID, String.t) :: :ok|:error
  def remove(manager, name) do
    GenServer.call(manager, {:remove, name})
  end

  @doc """
  Start a manager.
  """
  @spec start_link() :: PID
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, registry} = Registry.start_link()
    {:ok, %{registry: registry}}
  end

  def handle_call({:list}, _from, state) do
    {:reply, Registry.list(state.registry), state}
  end

  def handle_call({:add, name, source}, _from, state) do
    {:reply, Registry.add(state.registry, name, source), state}
  end

  def handle_call({:remove, name}, _from, state) do
    {:reply, Registry.remove(state.registry, name), state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
