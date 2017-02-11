defmodule Fifi.Source.Registry do
  @moduledoc """
  Registry for known sources of events.
  """
  use GenServer
  alias Fifi.Source.Source, as: Source

  ## Client API

  @doc """
  Starts the registry.
  """ 
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Adds a source to the registry.
  """
  @spec add(PID, String.t, Source) :: :ok|:error
  def add(server, name, source) do
    if Source.impl_for(source) == nil do
      raise ArgumentError, message: "Expected source to implement Fifi.Source.Source."
    end
    GenServer.call(server, {:add, name, source})
  end

  @doc """
  Get a source from the registry.
  """
  @spec get(PID, String.t) :: {:ok, Source}|:error
  def get(server, name) do
    GenServer.call(server, {:get, name})
  end

  @doc """
  Check if a source is contained in the registry.
  """
  @spec contains_source?(PID, String.t) :: boolean
  def contains_source?(server, name) do
    case get(server, name) do
      {:ok, _source} -> true
      :error -> false
    end
  end

  @doc """
  Remove a source from the registry.
  """
  @spec remove(PID, String.t) :: :ok|:error
  def remove(server, name) do
    GenServer.call(server, {:remove, name})
  end

  @doc """
  List all sources in the registry.
  """
  def list(server) do
    GenServer.call(server, {:list})
  end

  @doc """
  Set the PID for a source in the registry.
  """
  @spec set_pid(PID, String.t, PID) :: :ok|:error
  def set_pid(server, name, pid) when is_pid(pid) do
    GenServer.call(server, {:set_pid, name, pid})
  end

  @doc """
  Get the PID for a source in the registry.
  """
  @spec get_pid(PID, String.t) :: {:ok, PID}|:error
  def get_pid(server, name) do
    GenServer.call(server, {:get_pid, name})
  end

  ## Server Callbacks

  ## sets the server up. second arg is state.
  def init(:ok) do
    {:ok, %{}} 
  end

  ## call is for sync callbacks.
  def handle_call({:add, name, source}, _from, sources) do
    if not Map.has_key?(sources, name) do
      {:reply, :ok, Map.put(sources, name, {source, nil})}
    else
      {:reply, :error, sources}
    end
  end

  def handle_call({:get, name}, _from, sources) do
    res = case Map.fetch(sources, name) do
      {:ok, {source, _pid}} -> {:ok, source}
      :error -> :error
    end
    {:reply, res, sources}
  end

  def handle_call({:remove, name}, _from, sources) do
    if Map.has_key?(sources, name) do
      {:reply, :ok, Map.delete(sources, name)}
    else
      {:reply, :error, sources}
    end
  end

  def handle_call({:list}, _from, sources) do
    {:reply, Map.keys(sources), sources}
  end

  def handle_call({:set_pid, name, pid}, _from, sources) when is_pid(pid) do
    case Map.fetch(sources, name) do
      {:ok, {source, _pid}} -> {:reply, :ok, Map.put(sources, name, {source, pid})}
      :error -> {:reply, :error, sources}
    end
  end

  def handle_call({:get_pid, name}, _from, sources) do
    res = case Map.fetch(sources, name) do
      {:ok, {_source, pid}} -> case pid do
          nil -> :error
          pid -> {:ok, pid}
        end
      :error -> :error
    end
    {:reply, res, sources}
  end

  ## cast is for async callbacks, where clients don't care if msg really was
  ## passed.
  def handle_cast(_msg, sources) do
    {:noreply, sources}
  end

  ## info is for all other messages.
  def handle_info(_msg, sources) do
    {:noreply, sources}
  end
end
