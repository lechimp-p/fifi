defmodule Fifi.Source.Manager do
  @moduledoc """
  Entry point to the sources subsystem.
  """
  use GenServer
  alias Fifi.Source.Registry, as: Registry 
  alias Fifi.Source.Source, as: Source 

  @default_frequency 10_000

  @type listener :: (any -> any)

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
  @spec add_source(PID, String.t, Source) :: :ok|:error
  def add_source(manager, name, source) do
    GenServer.call(manager, {:add_source, name, source})
  end

  @doc """
  Remove a source from the manager.
  """
  @spec remove_source(PID, String.t) :: :ok|:error
  def remove_source(manager, name) do
    GenServer.call(manager, {:remove_source, name})
  end

  @doc """
  Add a listener for a source.
  """
  @spec add_listener(PID, String.t, listener) :: {:ok, reference}|:error
  def add_listener(manager, name, listener) do
    GenServer.call(manager, {:add_listener, name, listener})
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

  def handle_call({:add_source, name, source}, _from, state) do
    {:reply, Registry.add(state.registry, name, source), state}
  end

  def handle_call({:remove_source, name}, _from, state) do
    {:reply, Registry.remove(state.registry, name), state}
  end

  def handle_call({:add_listener, name, _listener}, _from, state) do
    case Registry.get(state.registry, name) do
      :error -> {:reply, :error, state}
      {:ok, source} -> case Source.start_link(source, @default_frequency, fn x -> IO.puts x end) do 
        {:error, _reason} -> {:reply, :error, state}
        {:ok, _pid} -> {:reply, {:ok, make_ref()}, state}
      end
    end
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
