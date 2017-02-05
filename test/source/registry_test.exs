defmodule Fifi.Source.RegistryTest do
  use ExUnit.Case, async: true
  doctest Fifi.Source.Registry

  alias Fifi.Source.Registry, as: Registry
  alias Fifi.Source.Null, as: Null

  setup do
    {:ok, registry} = Registry.start_link
    {:ok, registry: registry}
  end

  test "cannot get non existing", %{registry: registry} do
    assert Registry.get(registry, "foo") == :error
  end 

  test "cannot add non source", %{registry: registry} do
    assert_raise ArgumentError, fn ->
      Registry.add(registry, "foo", "bar")
    end
  end

  test "can add source", %{registry: registry} do
    assert Registry.add(registry, "null", %Null{}) == :ok
  end

  test "get existing source", %{registry: registry} do
    null = %Null{id: "some_id"}
    Registry.add(registry, "foo", null)
    assert Registry.get(registry, "foo") == {:ok, null}
  end
end
