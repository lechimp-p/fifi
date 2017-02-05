defmodule Fifi.Source.SPONTest do
  use ExUnit.Case, async: true
  doctest Fifi.Source.SPON

  alias Fifi.Source.Source, as: Source
  alias Fifi.Source.SPON, as: SPON

  setup do
    {:ok, %{spon: %SPON.Handle{}}}
  end

  test "description is moduledoc.", %{spon: spon} do
    assert String.valid?(Source.description(spon))
  end
end
