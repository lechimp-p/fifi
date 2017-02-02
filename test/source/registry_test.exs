defmodule Fifi.Source.RegistryTest do
  use ExUnit.Case, async: true
  alias Fifi.Source.Registry, as: Registry

  setup do
    {:ok, registry} = Registry.start_link
    {:ok, registry: registry}
  end

  test "get non existing", %{registry: registry} do
    assert Registry.get(registry, "foo") == :error
  end 

  test "get existing", %{registry: registry} do
    Registry.add(registry, "foo", "bar")
    assert Registry.get(registry, "foo") == {:ok, "bar"}
  end
end
