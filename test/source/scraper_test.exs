defmodule Fifi.Source.ScraperTest do
  use ExUnit.Case, async: true
  doctest Fifi.Source.Scraper

  alias Fifi.Source.Scraper, as: Scraper
  alias Fifi.Source.Source, as: Source

  setup do
    scraper = Scraper.build("http://www.example.com", ".title")
    {:ok, %{scraper: scraper}}
  end

  test "has valid description", %{scraper: scraper} do
    assert String.valid?(Source.description(scraper))
  end

  test "gives URL and CSS selector in description", %{scraper: scraper} do
    assert Source.description(scraper) == "Watches 'http://www.example.com' at '.title'."
  end
end
