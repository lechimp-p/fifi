defmodule Fifi.Source.Scraper do
  @moduledoc """
  A source that watches some DOM element defined by a CSS selector on a defined
  URL.
  """
  defmodule Handle do
    defstruct url: nil, css_selector: nil
  end

  @doc """
  Build a scraper by supplying an url to scrape and a CSS selector for a DOM
  element on said url.

  Will watch the first DOM element matching the selector.
  """
  @spec build(String.t, String.t) :: Fifi.Source.Source
  def build(url, css_selector) do
    %Handle{url: url, css_selector: css_selector}
  end
end

defimpl Fifi.Source.Source, for: Fifi.Source.Scraper.Handle do
  alias Fifi.Source.Scraper.Handle, as: Handle

  def description(%Handle{url: url, css_selector: css_selector})
    when is_binary(url)
    when is_binary(css_selector),
      do: ~s(Watches '#{url}' at '#{css_selector}'.)
end
