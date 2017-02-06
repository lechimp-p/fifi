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
end
