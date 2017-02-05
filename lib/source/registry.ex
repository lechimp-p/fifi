## Registry for known sources of events.
defmodule Fifi.Source.Registry do
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
  def add(server, name, source) do
    if Source.impl_for(source) == nil do
      raise ArgumentError, message: "Expected source to implement Fifi.Source.Source."
    end
    GenServer.call(server, {:add, name, source})
  end

  @doc """
  Get a source from the registry.
  """
  def get(server, name) do
    GenServer.call(server, {:get, name})
  end

  ## Server Callbacks

  ## sets the server up. second arg is state.
  def init(:ok) do
    {:ok, %{}} 
  end

  ## call is for sync callbacks.
  def handle_call({:add, name, source}, _from, sources) do
    {:reply, :ok, Map.put(sources, name, source)}
  end

  def handle_call({:get, name}, _from, sources) do
    {:reply, Map.fetch(sources, name), sources}
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
