defmodule Fifi.Source.Manager do
  @moduledoc """
  Entry point to the sources subsystem.
  """
  use GenServer
  alias Fifi.Source.Registry, as: Registry 
  alias Fifi.Source.Source, as: Source 
  alias Fifi.Source.Multiplexer, as: Multiplexer

  @default_frequency 10_000

  @type listener :: (any -> any)
  @type listener_ref :: {String.t, reference}

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
  @spec add_listener(PID, String.t, listener) :: {:ok, listener_ref}|:error
  def add_listener(manager, name, listener) do
    GenServer.call(manager, {:add_listener, name, listener})
  end

  @doc """
  Remove a listener.
  """
  @spec remove_listener(PID, listener_ref) :: :ok|:error
  def remove_listener(manager, ref) do
    GenServer.call(manager, {:remove_listener, ref})
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
    res = Registry.add(state.registry, name, source)
    if res == :ok do
      {:ok, multiplexer} = Multiplexer.start_link()
      :ok = Registry.set_info(state.registry, :multiplexer, name, multiplexer)
    end
    {:reply, res, state}
  end

  def handle_call({:remove_source, name}, _from, state) do
    {:reply, Registry.remove(state.registry, name), state}
  end

  def handle_call({:add_listener, name, listener}, _from, state) do
    case Registry.get_info(state.registry, :multiplexer, name) do
      :error -> {:reply, :error, state}
      {:ok, multiplexer} ->
        ref = Multiplexer.add(multiplexer, listener)
        if Multiplexer.count(multiplexer) == 1 do
          {:ok, source} = Registry.get(state.registry, name)
          on_update = fn v -> Multiplexer.call(multiplexer, v) end
          case Source.start_link(source, @default_frequency, on_update) do
            {:error, _reason} -> {:reply, :error, state}
            {:ok, pid} ->
              Registry.set_info(state.registry, :pid, name, pid)
              {:reply, {:ok, {name, ref}}, state}
          end
        else
          {:reply, {:ok, {name, ref}}, state}
        end
    end
  end

  def handle_call({:remove_listener, {name, ref}}, _from, state) do
    case Registry.get_info(state.registry, :multiplexer, name) do
      :error -> {:reply, :error, state}
      {:ok, multiplexer} ->
        :ok = Multiplexer.remove(multiplexer, ref)
        if Multiplexer.count(multiplexer) == 0 do
          case Registry.get_info(state.registry, :pid, name) do
            {:ok, pid} -> Process.exit(pid, "No one is listening to that source anymore.")
          end
        end
        {:reply, :ok, state}
    end
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
