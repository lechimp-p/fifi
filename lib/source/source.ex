defprotocol Fifi.Source.Source do
  @moduledoc """
  A source watches some thing on the internet and signals an event when something
  interesting happened there.

  We want to be open for many different types of sources, so we define a protocol 
  for sources rather than a concrete implementation.
  """

  @doc "Get a description of the source."
  @spec description(t) :: String.t
  def description(source)

  @type on_update :: (any -> nil)

  @doc "Start the source linked style, call given function on events."
  @spec start_link(t, pos_integer, on_update) :: GenServer.on_start
  def start_link(source, frequency, on_update)
end
