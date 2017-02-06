defmodule Fifi.Source.Scraper do
  @moduledoc """
  A source that watches some DOM element defined by a CSS selector on a defined
  URL.
  """
  @type extractor :: (Map -> any)

  defmodule Handle do
    defstruct url: nil, css_selector: nil, extractor: nil
  end

  @doc """
  Build a scraper by supplying an url to scrape, a CSS selector for a DOM
  element on said url and a function to extract the desired info from that
  element.

  Will watch the first DOM element matching the selector.
  """
  @spec build(String.t, String.t, extractor) :: Fifi.Source.Source
  def build(url, css_selector, extractor \\ &(&1)) do
    %Handle{url: url,
            css_selector: css_selector,
            extractor: extractor}
  end

  @doc """
  Scrape the value defined by the scraper.
  """
  @spec scrape(Handle) :: any
  def scrape(%Handle{url: url, css_selector: css_selector, extractor: extractor})
    when is_binary(url)
    when is_binary(css_selector)
    when is_function(extractor, 1)
    do
      HTTPoison.get!(url).body
        |> Floki.find(css_selector)
        |> hd()
        |> extractor.()
    end
end

defimpl Fifi.Source.Source, for: Fifi.Source.Scraper.Handle do
  alias Fifi.Source.Scraper.Handle, as: Handle

  def description(%Handle{url: url, css_selector: css_selector})
    when is_binary(url)
    when is_binary(css_selector),
      do: ~s(Watches '#{url}' at '#{css_selector}'.)
end
