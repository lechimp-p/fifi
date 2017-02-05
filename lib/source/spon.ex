defmodule Fifi.Source.SPON do
  @moduledoc """
  A source that watches the topmost headline on www.spiegel.de.
  """

  defmodule Handle do
    defstruct id: ()
  end

  def get_title do
    HTTPoison.get!("http://www.spiegel.de").body
      |> Floki.find(".article-title")
      |> Floki.find(".headline")
      |> hd()
      |> Floki.text()
      |> String.trim()
  end
end

defimpl Fifi.Source.Source, for: Fifi.Source.SPON.Handle do
  def description(_source), do: "Watches topmost headline of www.spiegel.de."
end
