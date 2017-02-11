defmodule Fifi.Source.Scraper do
  @moduledoc """
  A source that watches some DOM element defined by a CSS selector on a defined
  URL.

  # Example

  Scrape commits from GitHub like this:
    iex> url = "https://github.com/lechimp-p/fifi/commits/master"
    iex> css_selector = ".commit-title a"
    iex> extractor = &(&1 |> Floki.attribute("title") |> hd() |> String.trim())
    iex> s = Fifi.Source.Scraper.build(url, css_selector, extractor)
    iex> {ok?, _}  = Fifi.Source.Source.start_link(s, 10_000, &(IO.puts &1))
    iex> ok?
    :ok
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
      # TODO: if we would inject HTTPPoison.get this could be tested
      HTTPoison.get!(url).body
        |> Floki.find(css_selector)
        |> hd()
        |> extractor.()
    end

  @doc """
  Start the scraper, make it report changes via on_update.
  """
  @spec start_link(Handle, pos_integer, Fifi.Source.Source.on_update) :: GenServer.on_start
  def start_link(handle, frequency, on_update) do
    get_state = fn -> __MODULE__.scrape(handle) end
    Fifi.Source.Check.start_link(frequency, get_state, on_update)
  end
end

defimpl Fifi.Source.Source, for: Fifi.Source.Scraper.Handle do
  alias Fifi.Source.Scraper, as: Scraper 
  alias Fifi.Source.Scraper.Handle, as: Handle

  def description(%Handle{url: url, css_selector: css_selector})
    when is_binary(url)
    when is_binary(css_selector),
      do: ~s(Watches '#{url}' at '#{css_selector}'.)

  def start_link(handle, frequency, on_update),
      do: Scraper.start_link(handle, frequency, on_update)
end
