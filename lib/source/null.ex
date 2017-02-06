defmodule Fifi.Source.Null do
  defstruct id: ()
end

defimpl Fifi.Source.Source, for: Fifi.Source.Null do
  def description(_source), do: "A null source does nothing."
  def start_link(_source, _frequency, _on_update), do: {:error, "Can't start null source."}
end
