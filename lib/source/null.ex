defmodule Fifi.Source.Null do
  defstruct id: nil, description: nil, start_link: nil
end

defimpl Fifi.Source.Source, for: Fifi.Source.Null do
  @default_description ("A null source does nothing")

  def description(nil), do: @default_description
  def description(source), do: source.description

  def start_link(nil, _frequency, _on_update) do
    {:error, "Can't start null source."}
  end
  def start_link(source, frequency, on_update) do
    source.start_link.(frequency, on_update)
  end
end
