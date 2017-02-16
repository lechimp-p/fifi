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
  List all sources managed by the manager.
  """
  @spec list(PID) :: [String.t] 
  def list(manager) do
    GenServer.call(manager, {:list})
  end

  @doc """
  Check if the manager has a source.
  """
  @spec contains_source?(PID, String.t) :: boolean
  def contains_source?(manager, name) do
    GenServer.call(manager, {:contains_source?, name})
  end

  @doc """
  Add a source to the manager.
  """
  @spec add_source(PID, String.t, Source) :: :ok|{:error, String.t}
  def add_source(manager, name, source) do
    GenServer.call(manager, {:add_source, name, source})
  end

  @doc """
  Remove a source from the manager.
  """
  @spec remove_source(PID, String.t) :: :ok|{:error, String.t}
  def remove_source(manager, name) do
    GenServer.call(manager, {:remove_source, name})
  end

  @doc """
  Add a listener for a source.
  """
  @spec add_listener(PID, String.t, listener) :: {:ok, listener_ref}|{:error, String.t}
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
    {:ok, supervisor} = Supervisor.start_link([], strategy: :one_for_one)
    {:ok, %{registry: registry, supervisor: supervisor}}
  end

  def handle_call({:list}, _from, state) do
    {:reply, Registry.list(state.registry), state}
  end

  def handle_call({:contains_source?, name}, _from, state) do
    {:reply, Registry.contains_source?(state.registry, name), state}
  end

  def handle_call({:add_source, name, source}, _from, state) do
    if not Registry.contains_source?(state.registry, name) do
      :ok = Registry.add(state.registry, name, source)
      {:ok, multiplexer} = Multiplexer.start_link()
      :ok = Registry.set_info(state.registry, :multiplexer, name, multiplexer)
      {:reply, :ok, state}
    else
      {:reply, {:error, ~s(Manager already contains source '#{name}'.)}, state}
    end
  end

  def handle_call({:remove_source, name}, _from, state) do
    if Registry.contains_source?(state.registry, name) do
      :ok = Registry.remove(state.registry, name)
      {:reply, :ok, state}
    else
      {:reply, {:error, ~s(Manager contains no source '#{name}'.)}, state}
    end
  end

  def handle_call({:add_listener, name, listener}, _from, state) do
    if Registry.contains_source?(state.registry, name) do
      {:ok, multiplexer} = Registry.get_info(state.registry, :multiplexer, name)
      ref = Multiplexer.add(multiplexer, listener)
      # The first listener was just added.
      if Multiplexer.count(multiplexer) == 1 do
        start_source(state, name)
      end
      {:reply, {:ok, {name, ref}}, state}
    else
      {:reply, {:error, ~s(Manager contains no source '#{name}'.)}, state}
    end
  end

  def handle_call({:remove_listener, {name, ref}}, _from, state) do
    case Registry.get_info(state.registry, :multiplexer, name) do
      :error -> {:reply, :error, state}
      {:ok, multiplexer} ->
        :ok = Multiplexer.remove(multiplexer, ref)
        if Multiplexer.count(multiplexer) == 0 do
          # The last listener was removed.
          stop_source(state, name)
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

  # helpers for supervising source processes

  def start_source(state, name) do
    args = [state.registry, name, @default_frequency]
    options = [restart: :transient, function: :start_source_process]
    spec = Supervisor.Spec.worker(__MODULE__, args, options)
    Supervisor.start_child(state.supervisor, spec)
  end

  def stop_source(state, name) do
    {:ok, pid} = Registry.get_info(state.registry, :pid, name)
    Process.exit(pid, "No one is listening to that source anymore.")
  end

  def start_source_process(registry, name, frequency) do
    {:ok, source} = Registry.get(registry, name)
    {:ok, multiplexer} = Registry.get_info(registry, :multiplexer, name)
    on_update = fn v -> Multiplexer.call(multiplexer, v) end
    {:ok, pid} = Source.start_link(source, frequency, on_update)
    Registry.set_info(registry, :pid, name, pid)
    {:ok, pid}
  end
end
