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

  test "can't get non existing source", %{registry: registry} do
    assert Registry.get(registry, "foo") == :error
  end

  test "list existing sources", %{registry: registry} do
    one = %Null{id: "one"}
    Registry.add(registry, "one", one)
    two = %Null{id: "two"}
    Registry.add(registry, "two", two)
    assert Registry.list(registry) == ["one", "two"]
  end

  test "check for existing source", %{registry: registry} do
    assert not Registry.contains_source?(registry, "one")
    one = %Null{id: "one"}
    Registry.add(registry, "one", one)
    assert Registry.contains_source?(registry, "one")
  end

  test "can't add source with the same name", %{registry: registry} do
    one = %Null{id: "one"}
    :ok = Registry.add(registry, "one", one)
    two = %Null{id: "two"}
    :error = Registry.add(registry, "one", two)
  end

  test "remove source", %{registry: registry} do
    one = %Null{id: "one"}
    Registry.add(registry, "one", one)
    assert Registry.remove(registry, "one") == :ok
    assert Registry.get(registry, "one") == :error
    assert Registry.remove(registry, "one") == :error
  end

  test "set pid for source", %{registry: registry} do
    one = %Null{id: "one"}
    Registry.add(registry, "one", one)
    :ok = Registry.set_pid(registry, "one", self())
    assert Registry.get_pid(registry, "one") == {:ok, self()}
  end

  test "can't set pid for non-existing source", %{registry: registry} do
    assert Registry.set_pid(registry, "one", self()) == :error
  end

  test "can't get pid for non-existing source", %{registry: registry} do
    assert Registry.get_pid(registry, "one") == :error
  end

  test "can't get pid that was not set", %{registry: registry} do
    one = %Null{id: "one"}
    Registry.add(registry, "one", one)
    assert Registry.get_pid(registry, "one") == :error
  end

  test "remove pid when removing source", %{registry: registry} do
    one = %Null{id: "one"}
    Registry.add(registry, "one", one)
    Registry.set_pid(registry, "one", self())
    Registry.remove(registry, "one")
    assert Registry.get_pid(registry, "one") == :error
  end
end
